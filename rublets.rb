#!/usr/bin/env ruby
# encoding: utf-8
require 'fileutils'
require 'timeout'
require 'net/https'
require 'uri'

require 'rubygems'
require 'bundler/setup'
require 'json'
require 'on_irc'
require 'future'
require 'configru'
require 'nokogiri'
require 'pry'

$LOAD_PATH.unshift File.dirname(__FILE__)
require 'eval/eval'
require 'eval/languages'

Configru.load do
  just 'rublets.yml'
  
  defaults do
    servers {}
    nickname 'rublets'
    comchar '!'
    default_ruby 'ruby-1.9.3-p0'
    version_command 'rpm -qf'
  end

  verify do
    nickname /^[A-Za-z0-9_\`\[\{}^|\]\\-]+$/
  end
end

#bot = Thread.new do
@bot = IRC.new do
  nick Configru.nickname
  ident Configru.nickname
  realname 'Ruby Safe-Eval bot.'

  Configru.servers.each_pair do |name, server_cfg|
    server name do
      address server_cfg.address
    end
  end
end

Configru.servers.each_pair do |name, server_cfg|
  @bot[name].on '001' do
    server_cfg.channels.each do |channel|
      join channel
    end
  end
end

@bot.on :ping do
  pong params[0]
end

@bot.on :privmsg do
  begin
    matches = params[1].match(/^#{Configru.comchar}(\S+)> ?(.*)/)
    if matches
      the_lang = Language.by_name(matches[1])
      if the_lang != nil
        future do
          sandbox = Sandbox.new(the_lang.merge({:owner => sender.nick, :code => matches[2], :github_credentials => Configru.github_credentials}))
          the_lang[:required_files].each { |file,dest| sandbox.copy file, dest } unless the_lang[:required_files].nil?
          result = sandbox.evaluate
          result.each { |line| respond line }
          sandbox.rm_home!
          next
        end
      end
    end
    
    case params[1]
    when /^#{Configru.comchar}version (.+)/
      language = Language.by_name($1)
      respond Language.version(language, Configru.version_command) and next unless language.nil?
      respond "That language is not supported."
    when /^#{Configru.comchar}rubies$/
      # Lists all available rubies.
      rubies = Dir['./rubies/*'].map { |a| File.basename(a) }
      respond "#{sender.nick}: #{rubies.join(', ')} (You can specify 'all' to evaluate against all rubies, but this might be slowish.)"

    when /^#{Configru.comchar}lang(?:s|uages)$/
      respond "\x01ACTION supports: #{Language.list_all}\x01"

    when /^#{Configru.comchar}<\?(php|php=|=|) (.*)/
      respond "#{sender.nick}, this PHP syntax is deprecated.  Use !php> <?php /* Your code */ instead."
      if not $1.nil? and $1.end_with? '='
        code = "<?php echo #{$2}"
      else
        code = "<?php #{$2}"
      end
      future do
        sandbox = Sandbox.new(
          :path               => File.expand_path('~/.rublets'),
          :evaluate_with      => ['php'],
          :timeout            => 5,
          :extension          => 'php',
          :owner              => sender.nick,
          :output_limit       => 2,
          :code               => code,
          :github_credentials => Configru.github_credentials
        )
        result = sandbox.evaluate
        result.each { |line| respond line }
        sandbox.rm_home!
      end

      # Special cased to warn about using ;; for \n
    when /^#{Configru.comchar}lolcode> (.*)/i
      code = $1
        sandbox = Sandbox.new(
          :path          => File.expand_path('~/.rublets'),
          :evaluate_with => ['lol-pl'],
          :timeout       => 5,
          :extension     => 'lol',
          :output_limit  => 2,
          :github_credentials => Configru.github_credentials,
          :code          => code,
          :alter_code    => lambda { |code|
            code.gsub(";;", "\n")
          }
        )
        if code.include? ";" and !code.include? ";;"
          respond "USE ;; 2 SEPURRRATE UR CODEZ N INSURT NEW LINE KTHX"
        end
        result = sandbox.evaluate
        result.each { |line| respond line }
        sandbox.rm_home!


    # Ruby eval.
    when /^#{Configru.comchar}(([\w\.\-]+)?>?|>)> (.*)/
      future do
        # Pull these out of the regex here, because the global captures get reset below.
        given_version = $2 # might be nil.
        code = $3

        #future do # We can have multiple evaluations going on at once.
        rubyversion = Configru.default_ruby

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
              next
            end
            rubyversion = rubies[0]
          end
        end

        eval_code = "result = ::Kernel.eval(#{code.inspect}, TOPLEVEL_BINDING)"
        if rubyversion == 'all'
          eval_code += "\n" + 'puts RUBY_VERSION + " #{\'(\' + RUBY_ENGINE + \')\' unless defined?(RUBY_ENGINE).nil?} => " + result.inspect'
        else
          eval_code += "\n" + 'puts "=> " + result.inspect'
        end

        sandbox = Sandbox.new(
          :path                => File.expand_path('~/.rublets'),
          :evaluate_with       => ['bash', 'run-ruby.sh', rubyversion],
          :timeout             => 5,
          :extension           => 'rb',
          :owner               => sender.nick,
          :output_limit        => 2,
          :code                => eval_code,
          :binaries_must_exist => ['ruby', 'bash'],
          :github_credentials  => Configru.github_credentials
          )

        sandbox.copy 'rvm', '.rvm'

        # If the user wants to eval against all rubies, then copy the entire rubies directory.
        if rubyversion == 'all'
          sandbox.copy 'rubies', '.rvm/rubies/'
        else
          sandbox.mkdir(".rvm/rubies")
          sandbox.copy "rubies/#{rubyversion}", ".rvm/rubies/#{rubyversion}"
        end

        # This is a bit of a hack, but lets us set up the rvm environment and call the script.
        sandbox.copy 'eval/run-ruby.sh', 'run-ruby.sh'
        result = sandbox.evaluate
        result.each { |line| respond line }
        sandbox.rm_home!
      end
    end # end case
  rescue ThreadError
    respond "Could not create thread."
  end
end # end on :privmsg
@bot.connect
#end # end thread

#bot.join
