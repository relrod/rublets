#!/usr/bin/env ruby

load File.join(File.dirname(__FILE__), 'lib', 'bot.rb')

trap("INT") { $manager.shutdown }

#bot = Rubino::Bot.new(:server => 'irc.ninthbit.net', :channels => ['#programming'])
#bot.connect
#bot.run

if ARGV.size > 0
  $manager = Rubino::Manager.new(ARGV[0])
else
  $manager = Rubino::Manager.new(File.join(File.dirname(__FILE__), 'config.yaml'))
end

$manager.run
$manager.connection_check_loop
