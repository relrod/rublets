#!/usr/bin/env ruby
# encoding: utf-8
require 'fileutils'
require 'timeout'
require 'net/https'
require 'uri'

require './eval.rb'

require 'rubygems'
require 'bundler/setup'
require 'json'
require 'on_irc'
require 'future'

require 'pry'

#bot = Thread.new do
@bot = IRC.new do
  nick 'rublets'
  ident 'rublets'
  realname 'Ruby Safe-Eval bot.'

  # TODO: Make this config file managable.
  server :tenthbit do
    address 'irc.tenthbit.net'
  end

  server :freenode do
    address 'irc.freenode.net'
  end
end

@bot[:tenthbit].on '001' do
  join '#bots'
  join '#offtopic'
end

@bot[:freenode].on '001' do
end

@bot.on :ping do
  pong params[0]
end

@bot.on :privmsg do
  case params[1]
  when /^!rubies$/
    # Lists all available rubies.
    rubies = Dir['./rubies/*'].map { |a| File.basename(a) }
    respond "#{sender.nick}: #{rubies.join(', ')} (You can specify 'all' to evaluate against all rubies, but this might be slowish.)"

    # Scala eval.
  when /^!scala> (.*)/
    unless ENV['PATH'].split(':').any? { |path| File.exists? path + '/scala' }
      respond "Scala is not available on this box." and next
    end
    
    # Pull these out of the regex here, because the global captures get reset below.
    code = $1

    future do # We can have multiple evaluations going on at once.
      sandbox = Sandbox.new(
        :path => File.expand_path('~/.rublets'),
        :evaluate_with => ['scala', '-nocompdaemon'],
        :timeout => 20
        )

      time = sandbox.time
      file = "#{time.year}-#{time.month}-#{time.day}_#{time.hour}-#{time.min}-#{time.sec}-#{sender.nick}-#{time.to_f}.scala"
      sandbox.script_filename = file

      # Write the script.
      rb = File.open("#{sandbox.home}/#{file}", 'w')
      rb.puts code
      rb.close

      result = sandbox.evaluate

      # Limit output to two lines, then gist the rest.
      limit = 2
      lines = result.split("\n")
      lines[0...limit].each do |line|
        respond line
      end
      if lines.count > limit
        respond "<output truncated> #{sandbox.gist}"
      end
      
      sandbox.rm_home!
    end

    # Ruby eval.
  when /^!([\w\.\-]+)?>> (.*)/
    # Pull these out of the regex here, because the global captures get reset below.
    given_version = $1 # might be nil.
    code = $2

    # User wants to evaluate some ruby code.
    #future do # We can have multiple evaluations going on at once.

      rubyversion = 'ruby-1.9.3-p0' # Default, set here for scoping. TODO: Config-file this.

      # If a version is given (so not default), scan ./rubies/* to see if it matches.
      # If there is one (and only one) match, move along and set rubyversion to that.
      # If there's more than one, or no match, warn the user and ignore the eval.
      unless given_version.nil?
        if given_version == 'all'
          rubyversion = 'all'
        else
          rubies = Dir['./rubies/*'].map { |a| File.basename(a) }
          rubies = rubies.delete_if { |ruby| ruby.scan(given_version).empty? }
          if rubies.count > 1
            respond "#{sender.nick}: You matched multiple rubies. Be more specific. See !rubies for the full list." and next
          elsif rubies.count == 0
            respond "#{sender.nick}: That ruby isn't available. See !rubies for a list." and next
          end
          rubyversion = rubies[0]
        end
      end

      sandbox = Sandbox.new(
        :path => File.expand_path('~/.rublets'),
        :evaluate_with => ['bash', 'run-ruby.sh', rubyversion],
        :timeout => 5
        )

      time = sandbox.time
      file = "#{time.year}-#{time.month}-#{time.day}_#{time.hour}-#{time.min}-#{time.sec}-#{sender.nick}-#{time.to_f}.rb"
      sandbox.script_filename = file

      sandbox.copy 'rvm', '.rvm'

      # If the user wants to eval against all rubies, then copy the entire rubies directory.
      if rubyversion == 'all'
        sandbox.copy 'rubies', '.rvm/rubies/'
      else
        sandbox.mkdir(".rvm/rubies")
        sandbox.copy "rubies/#{rubyversion}", ".rvm/rubies/#{rubyversion}"
      end

      # This is a bit of a hack, but lets us set up the rvm environment and call the script.
      sandbox.copy 'run-ruby.sh', 'run-ruby.sh'

      # Write the script.
      rb = File.open("#{sandbox.home}/#{file}", 'w')

      # Capture output so we can default a "puts" if the user just wants the return value.
      rb.puts "result = ::Kernel.eval(#{code.inspect}, TOPLEVEL_BINDING)"

      # Give the version along with the response, if evaluating against all
      # rubies, so the user knows which is which.
      if rubyversion == 'all'
        rb.puts 'puts RUBY_VERSION + " #{\'(\' + RUBY_ENGINE + \')\' unless defined?(RUBY_ENGINE).nil?} => " + result.inspect'
      else
        rb.puts 'puts "=> " + result.inspect'
      end
      rb.close

      #binding.pry
      result = sandbox.evaluate

      # Limit output to two lines, then gist the rest.
      lines = result.split("\n")
      limit = (rubyversion == 'all') ? Dir['./rubies/*'].count : 2 #TODO: Config-file this.
      if lines.any? { |l| l.length > 255 }
        respond "<output is long> #{sandbox.gist}"
      else
        lines[0...limit].each do |line|
          respond line
        end
        if lines.count > limit
          respond "<output truncated> #{sandbox.gist}"
        end
      end
      
      sandbox.rm_home!

    #end # end future
  end # end case
end # end on :privmsg
@bot.connect
#end # end thread

#bot.join
