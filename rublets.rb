#!/usr/bin/env ruby
# encoding: utf-8
require 'fileutils'
require 'timeout'
require 'net/https'
require 'uri'

require './eval/eval.rb'

require 'rubygems'
require 'bundler/setup'
require 'json'
require 'on_irc'
require 'future'
require 'configru'

require 'pry'

Configru.load do
  just 'rublets.yml'
  
  defaults do
    servers {}
    nickname 'rublets'
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
    case params[1]
    when /^!rubies$/
      # Lists all available rubies.
      rubies = Dir['./rubies/*'].map { |a| File.basename(a) }
      respond "#{sender.nick}: #{rubies.join(', ')} (You can specify 'all' to evaluate against all rubies, but this might be slowish.)"

    when /^!scala> (.*)/
      future do
        sandbox = Sandbox.new(
          :path => File.expand_path('~/.rublets'),
          :evaluate_with => ['scala', '-J-server', '-J-XX:+TieredCompilation', '-nocompdaemon'],
          :timeout => 20,
          :extension => 'scala',
          :owner => sender.nick,
          :output_limit_before_gisting => 2,
          :code => $1
          )
        result = sandbox.evaluate
        result.each { |line| respond line }
        sandbox.rm_home!
      end

    when /^!c> (.*)/
      includes = [
        '#include <stdio.h>',
        '#include <stdint.h>',
        '#include <string.h>',
        '#include <math.h>',
        '#include <stdlib.h>',
        '#include <time.h>',
        '#include <limits.h>',
        '#include <unistd.h>',
        '#include <sys/types.h>',
        '#include <sys/socket.h>',
        '#include <fcntl.h>',
        '#include <signal.h>',
        '#include <netdb.h>',
        '#include <errno.h>',
      ]
      code = includes.join("\n") + "\n"
      code += $1
      
      future do
        sandbox = Sandbox.new(
          :path => File.expand_path('~/.rublets'),
          :evaluate_with => ['bash', 'run-c.sh'],
          :binaries_must_exist => ['gcc', 'bash'],
          :timeout => 5,
          :extension => 'c',
          :owner => sender.nick,
          :output_limit_before_gisting => 2,
          :code => code
          )
        sandbox.copy 'eval/run-c.sh', 'run-c.sh'
        result = sandbox.evaluate
        result.each { |line| respond line }
        sandbox.rm_home!
      end

    when /^!c\+\+> (.*)/
      includes = [
        '#include <cmath>',
        '#include <cstdint>',
        '#include <string>',
        '#include <map>',
        '#include <vector>',
        '#include <algorithm>',
        '#include <deque>',
        '#include <sstream>',
        '#include <fstream>',
        '#include <iostream>',
        '#include <iomanip>',
        '#include <thread>',
        '#include <mutex>',
        'using namespace std;',
      ]
      code = includes.join("\n") + "\n"
      code += $1
      
      future do
        sandbox = Sandbox.new(
          :path => File.expand_path('~/.rublets'),
          :evaluate_with => ['bash', 'run-cpp.sh'],
          :binaries_must_exist => ['g++', 'bash'],
          :timeout => 5,
          :extension => 'cpp',
          :owner => sender.nick,
          :output_limit_before_gisting => 2,
          :code => code
          )
        sandbox.copy 'eval/run-cpp.sh', 'run-cpp.sh'
        result = sandbox.evaluate
        result.each { |line| respond line }
        sandbox.rm_home!
      end

    when /^!forth> (.*)/
      future do
        sandbox = Sandbox.new(
          :path => File.expand_path('~/.rublets'),
          :evaluate_with => ['gforth'],
          :timeout => 5,
          :extension => 'forth',
          :owner => sender.nick,
          :output_limit_before_gisting => 2,
          :code => $1 + ' bye'
        )
        result = sandbox.evaluate
        result.each { |line| respond line }
        sandbox.rm_home!
      end

    when /^!(?:bash|\$)> (.*)/
      future do
        sandbox = Sandbox.new(
          :path => File.expand_path('~/.rublets'),
          :evaluate_with => ['bash'],
          :timeout => 5,
          :extension => 'sh',
          :owner => sender.nick,
          :output_limit_before_gisting => 2,
          :code => $1
        )
        result = sandbox.evaluate
        result.each { |line| respond line }
        sandbox.rm_home!
      end

      # Ruby eval.
    when /^!([\w\.\-]+)?>> (.*)/
      # Pull these out of the regex here, because the global captures get reset below.
      given_version = $1 # might be nil.
      code = $2

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

      eval_code = "result = ::Kernel.eval(#{code.inspect}, TOPLEVEL_BINDING)"
      if rubyversion == 'all'
        eval_code += "\n" + 'puts RUBY_VERSION + " #{\'(\' + RUBY_ENGINE + \')\' unless defined?(RUBY_ENGINE).nil?} => " + result.inspect'
      else
        eval_code += "\n" + 'puts "=> " + result.inspect'
      end

      sandbox = Sandbox.new(
        :path => File.expand_path('~/.rublets'),
        :evaluate_with => ['bash', 'run-ruby.sh', rubyversion],
        :timeout => 5,
        :extension => 'rb',
        :owner => sender.nick,
        :output_limit_before_gisting => 2,
        :code => eval_code,
        :binaries_must_exist => ['ruby', 'bash'],
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
      #    end
    end # end case
  rescue ThreadError
    respond "Could not create thread."
  end
end # end on :privmsg
@bot.connect
#end # end thread

#bot.join
