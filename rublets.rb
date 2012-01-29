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

# Check if `sandbox` exists.
unless ENV['PATH'].split(':').any? { |path| File.exists? path + '/sandbox' }
  raise "The `sandbox` executable does not exist and is required."
end

def gist(nickname, input, output)
  gist = URI.parse('https://api.github.com/gists')
  http = Net::HTTP.new(gist.host, gist.port)
  http.use_ssl = true
  response = http.post(gist.path, {
      'public' => false,
      'description' => "#{nickname}'s ruby eval",
      'files' => {
        'input.rb' => {
          'content' => input
        },
        'output.txt' => {
          'content' => output
        }
      }
    }.to_json)
  if response.response.code.to_i != 201
    return 'Unable to post to Gist.'
  else
    JSON(response.body)['html_url']
  end
end

#bot = Thread.new do
@bot = IRC.new do
  nick 'rublets'
  ident 'rublets'
  realname 'Ruby Safe-Eval bot.'

  # TODO: Make this config file managable.
  server :tenthbit do
    address 'irc.tenthbit.net'
  end
end

@bot[:tenthbit].on '001' do
  join '#bots'
  #join '#progamming'
  #join '#offtopic'
end

@bot[:tenthbit].on :ping do
  pong params[0]
end

@bot.on :privmsg do
  case params[1]
  when /^!rubies$/
    # Lists all available rubies.
    rubies = Dir['./rubies/*'].map { |a| File.basename(a) }
    respond "#{sender.nick}: #{rubies.join(', ')} (You can specify 'all' to evaluate against all rubies, but this might be slowish.)"

  when /^!([\w\.\-]+)?>> (.*)/

    # Pull these out of the regex here, because the global captures get reset below.
    given_version = $1 # might be nil.
    code = $2

    unless sender.nick =~ /^\w+$/i
      respond "#{sender.nick}: Please use an alphanumeric nick, for now. This requirement should be fixed eventually." and next
    end

    # User wants to evaluate some ruby code.
    future do # We can have multiple evaluations going on at once.

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

      time = Time.now # Used for filename generation below.
      file = "#{time.year}-#{time.month}-#{time.day}_#{time.hour}-#{time.min}-#{time.sec}-#{sender.nick}-#{time.to_f}.rb"

      sandbox_path = File.expand_path('~/.rublets')
      sandbox_home = "#{sandbox_path}/sandbox_home-#{time.to_f}"
      
      # Make the sandbox home (specific to this eval, as per Time.now above.
      FileUtils.mkdir sandbox_home

      # Move rvm into the sandbox's home, along with the appropriate ruby.
      FileUtils.cp_r('rvm', "#{sandbox_home}/.rvm")

      # If the user wants to eval against all rubies, then copy the entire rubies directory.
      if rubyversion == 'all'
        FileUtils.cp_r("rubies/", "#{sandbox_home}/.rvm/rubies/")
      else
        FileUtils.mkdir("#{sandbox_home}/.rvm/rubies")
        FileUtils.cp_r("rubies/#{rubyversion}", "#{sandbox_home}/.rvm/rubies/#{rubyversion}")
      end

      # This is a bit of a hack, but lets us set up the rvm environment and call the script.
      FileUtils.cp('run-ruby.sh', "#{sandbox_home}/run-ruby.sh")

      # Write the script.
      rb = File.open("#{sandbox_home}/#{file}", 'w')

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

      # Copy the script to somewhere outside of the sandbox, for audit purposes.
      FileUtils.cp("#{sandbox_home}/#{file}", "#{sandbox_path}/evaluated/#{file}")

      # The magic. Sandbox!
      result = `sandbox -H #{sandbox_home}/ -T #{sandbox_path}/sandbox_tmp/ -t sandbox_x_t timeout 5 bash run-ruby.sh #{rubyversion} #{file} 2>&1`
      result = '(No output)' if result.empty?

      # Limit output to two lines, then gist the rest.
      lines = result.split("\n")
      limit = (rubyversion == 'all') ? Dir['./rubies/*'].count : 2 #TODO: Config-file this.
      lines[0...limit].each do |line|
        respond line
      end
      if lines.count > limit
        respond "<output truncated> #{gist(sender.nick, code, result)}"
      end

      # Clean up clean up clean up
      FileUtils.rm_rf sandbox_home

    end # end future
  end # end case
end # end on :privmsg
@bot.connect
#end # end thread

#bot.join
