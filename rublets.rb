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
require 'nokogiri'
require 'pry'
require 'linguist/repository'

$LOAD_PATH.unshift File.dirname(__FILE__)
require 'eval/config'
require 'eval/eval'
require 'eval/languages'
require 'statistics-web/extra_languages'

Signal.trap("USR1") do
  begin
    # Allow for reloading, on-the-fly, some of our core files.
    load File.dirname(__FILE__) + "/eval/eval.rb"
    load File.dirname(__FILE__) + "/eval/languages.rb"
  rescue Exception => e
    puts "-" * 80
    puts "** Reload (USR1) Exception **"
    puts "#{e} (#{e.class})"
    puts e.backtrace
    puts "-" * 80
  end
end

sandbox_net_t_users = Configru.sandbox_net_t_users.map do |hostmask|
  Regexp.new(hostmask)
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
  puts "#{Time.now} #{params[0]} <#{sender.nick}> #{params[1]}"
  begin
    matches = params[1].match(/^#{Configru.comchar}([\S]+)> ?(.*)/i)
    if matches.nil?
      matches = params[1].match(/\[\[([\w\d]+)(?::|) (.*)\]\]/i)
    end
    if matches && matches.size > 1
      the_lang = Language.by_name(matches[1])
      if the_lang
        future do
          sandbox = Sandbox.new(the_lang.merge({
                :owner                => sender.nick,
                :code                 => matches[2],
                :pastebin_credentials => Configru.pastebin_credentials,
                :path                 => Configru.rublets_home,
                :sandbox_net_t        => (sandbox_net_t_users.any? { |regex| !sender.host.match(regex).nil? })
              }))
          sandbox.initialize_directories
          the_lang[:required_files].each { |file,dest| sandbox.copy file, dest } unless the_lang[:required_files].nil?
          result = sandbox.evaluate
          result.each { |line| respond line }
          sandbox.rm_home!
        end
        next
      end
    end

    case params[1]
    when /^#{Configru.comchar}version (.+)/
      versions = []
      $1.gsub(' ', '').split(',').each do |given_language|
        language = Language.by_name(given_language)
        if language
          if version = Language.version(language, Configru.version_command)
            versions << version
          else
            versions << "[Unable to detect version for #{given_language}]"
          end
        else
          versions << "['#{given_language}' is not supported]"
        end
      end
      respond versions.join(', ')
    when /^#{Configru.comchar}quickstats$/
      project = Linguist::Repository.from_directory("#{Configru.rublets_home}/evaluated/")
      languages = {}
      project.languages.each do |language, count|
        languages[language.name] = ((count.to_f/project.size)*100).round(2)
      end
      top_languages = Hash[*languages.sort_by { |k, v| v }.reverse[0...8].flatten]
      total_evals = Dir["#{Configru.rublets_home}/evaluated/*"].count
      respond "#{sender.nick}: #{total_evals} total evaluations. " + top_languages.map { |k,v| "#{k}: #{v}%"}.join(', ') + " ... "
    when /^#{Configru.comchar}rubies$/
      # Lists all available rubies.
      rubies = Dir[File.join(Configru.rvm_path, 'rubies') + '/*'].map { |a| File.basename(a) }
      respond "#{sender.nick}: #{rubies.join(', ')} (You can specify 'all' to evaluate against all rubies, but this might be slowish.)"

    when /^#{Configru.comchar}lang(?:s|uages)$/
      respond "\x01ACTION supports: #{Language.list_all}\x01"

    # Ruby eval.
    when /^#{Configru.comchar}(([\w\.\-]+)?>?|>)> (.*)/
      future do
        # Pull these out of the regex here, because the global captures get reset below.
        given_version = $2 # might be nil.
        code = $3

        rubyversion = Configru.default_ruby

        # If a version is given (so not default), scan ./rubies/* to see if it matches.
        # If there is one (and only one) match, move along and set rubyversion to that.
        # If there's more than one, or no match, warn the user and ignore the eval.
        unless given_version.nil?
          if given_version == 'all'
            rubyversion = 'all'
          else
            rubies = Dir[File.join(Configru.rvm_path, 'rubies') + '/*'].map { |a| File.basename(a) }
            rubies = rubies.delete_if { |ruby| ruby.scan(given_version).empty? }
            if rubies.count > 1
              if rubies.include? given_version
                rubyversion = given_version
              else
                respond "#{sender.nick}: You matched multiple rubies. Be more specific. See !rubies for the full list." and next
              end
            elsif rubies.count == 0
              next
            end
            rubyversion = rubies[0]
          end
        end

        eval_code = "begin\n"
        eval_code += "  result = ::Kernel.eval(#{code.inspect}, TOPLEVEL_BINDING)\n"
        if rubyversion == 'all'
          eval_code += '  puts RUBY_VERSION + " #{\'(\' + RUBY_ENGINE + \')\' unless defined?(RUBY_ENGINE).nil?} => " + result.inspect' + "\n"
        else
          eval_code += '  puts "=> " + result.inspect' + "\n"
        end
        eval_code += "rescue Exception => e\n"
        eval_code += '  puts "#{e.class}: #{e.message}"'
        eval_code += "\nend"

        sandbox = Sandbox.new(
          :path                 => Configru.rublets_home,
          :evaluate_with        => ['bash', 'run-ruby.sh', Configru.rvm_path, rubyversion],
          :timeout              => 5,
          :extension            => 'rb',
          :language_name        => 'ruby',
          :owner                => sender.nick,
          :output_limit         => 2,
          :code                 => eval_code,
          :binaries_must_exist  => ['ruby', 'bash'],
          :pastebin_credentials => Configru.pastebin_credentials
          )

        # This is a bit of a hack, but lets us set up the rvm environment and call the script.
        sandbox.initialize_directories
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
