#!/usr/bin/env ruby

require 'configru'
require 'cinch'

load File.join(File.dirname(__FILE__), 'safeeval', 'safeeval.rb')
load File.join(File.dirname(__FILE__), 'gist.rb')

Configru.load do
  just File.join(File.dirname(__FILE__), 'config.yml')
  defaults File.join(File.dirname(__FILE__), 'config.yml.dist')

  verify do
    servers do
      channels Array
      address  String
      port     (0..65535)
    end
  end
end

bots = []
threads = []

SafeEval.setup

Configru.servers.each do |bot|
  bots << Cinch::Bot.new do
    configure do |c|
      c.server   = bot['address']
      c.port     = bot['port']
      c.channels = bot['channels']
      c.nick     = Configru.nick
    end
    
    on :message, /^>> / do |m|
      _, code = m.message.split(' ', 2)
      result = SafeEval.run(code, m.user.nick)
      result = '(No output)' if result.empty?

      lines = result.split("\n")

      limit = 2

      lines[0...limit].each do |line|
        m.reply(line, true)
      end
    end
  end
  
  threads << Thread.new { bots[-1].start }
  sleep 1
end

threads[-1].join
