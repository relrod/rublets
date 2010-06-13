#!/usr/bin/env ruby

load File.join(File.dirname(__FILE__), 'lib', 'bot.rb')

bot = Rubino::Bot.new(:server => 'irc.ninthbit.net', :channels => ['#programming'])
bot.connect
bot.run
