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
require 'evalso'
require 'httparty'

$LOAD_PATH.unshift File.dirname(__FILE__)
require 'eval/config'
require 'eval/eval'
require 'eval/languages'
require 'statistics-web/extra_languages'

Signal.trap("USR1") do
  begin
    # Allow for reloading, on-the-fly, some of our core files.
    load File.dirname(__FILE__) + "/eval/config.rb"
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
    server_cfg.channels.each_slice(4).each do |channel_arr|
      join channel_arr.join(',')
    end
  end
end

@bot.on :ping do
  pong params[0]
end

@bot.on :privmsg do
  puts "#{Time.now} #{params[0]} <#{sender.nick}> #{params[1]}"
  if params[0] == Configru.nickname &&
     !Configru.servers[server.name.to_s].pm_hosts.nil? &&
     !Configru.servers[server.name.to_s].pm_hosts.include?(sender.host)
    next
  end
  limit = Configru.servers[server.name.to_s].channel_options
  limit &&= limit.find { |n| n['channel'] == params[0] }
  limit &&= limit['limit']
  begin
    matches = params[1].match(/^#{Configru.comchar}([\S]+)> ?(.*)/i)
    if matches.nil?
      matches = params[1].match(/\[\[([\S]+)(?::|) (.*)\]\]/i)
    end
    if matches && matches.size > 1
      the_lang = Language.by_name(matches[1])
      if the_lang
        future do
          line_limit = the_lang[:output_limit] || limit
          sandbox = Sandbox.new(the_lang.merge({
                :owner                => sender.nick,
                :code                 => matches[2],
                :pastebin_credentials => Configru.pastebin_credentials,
                :path                 => Configru.rublets_home,
                :output_limit         => line_limit,
                :channel              => params[0],
                :server               => server.name.to_s,
              }))
          sandbox.initialize_directories
          chmod = the_lang[:required_files_perms] ? the_lang[:required_files_perms] : 0770
          the_lang[:required_files].each { |file,dest| sandbox.copy(file, dest, chmod) } unless the_lang[:required_files].nil?
          result = sandbox.evaluate
          result.each { |line| respond line }
          sandbox.rm_home!
        end
        next
      end
    end

    case params[1]
    when /^#{Configru.comchar}#{Configru.comchar}([\S]+)> ?(.*)/i
      future do
        begin
          res = Evalso.run(:language => $1, :code => $2)
          stdout = if res.stdout != "" then "#{2.chr}stdout:#{2.chr} #{res.stdout} " else " " end
          stderr = if res.stderr != "" then "#{2.chr}stderr:#{2.chr} #{res.stderr}" else "" end
          respond "[#{res.wall_time} ms] #{stdout}#{stderr}"
        rescue
          respond "An error occurred while communicating with eval.so"
        end
      end
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
    #when /^#{Configru.comchar}quickstats$/
    #  project = Linguist::Repository.from_directory("#{Configru.rublets_home}/evaluated/")
    #  languages = {}
    #  project.languages.each do |language, count|
    #    languages[language.name] = ((count.to_f/project.size)*100).round(2)
    #  end
    #  top_languages = Hash[*languages.sort_by { |k, v| v }.reverse[0...8].flatten]
    #  total_evals = Dir["#{Configru.rublets_home}/evaluated/*"].count
    #  respond "#{sender.nick}: #{total_evals} total evaluations. " + top_languages.map { |k,v| "#{k}: #{v}%"}.join(', ') + " ... "
    when /^#{Configru.comchar}lang(?:s|uages)$/
      respond "#{1.chr}ACTION supports: #{Language.list_all}#{1.chr}"

    when /^#{Configru.comchar}#{Configru.comchar}lang(?:s|uages)$/
      respond "Eval.so supports: #{Evalso.languages.values.map(&:name).sort.join(', ')}"

    when /^#{Configru.comchar}join (.+)$/
      if Configru.servers[server.name.to_s].admins.include? sender.host
        join $1
      else
        respond "#{sender.nick}: You need to be an administrator to have the bot join and part channels."
      end

    when /^#{Configru.comchar}part (.+)$/
      if Configru.servers[server.name.to_s].admins.include? sender.host
        part $1
      else
        respond "#{sender.nick}: You need to be an administrator to have the bot join and part channels."
      end
    end # end case
  rescue ThreadError
    respond "Could not create thread."
  end
end # end on :privmsg
@bot.connect
#end # end thread

#bot.join
