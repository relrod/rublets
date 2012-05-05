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
require 'pry'

$LOAD_PATH.unshift File.dirname(__FILE__)
require '../eval/languages'

@bot = IRC.new do
  nick 'testlets'
  ident 'testlets'
  realname 'Rublets Test Suite'

  server :test do
    address 'irc.tenthbit.net'
  end
end

@bot[:test].on '001' do
  # Start tests.
  $correct_response = 'foobar'
end

@bot[:test].on :ping do
  pong params[0]
end

@bot[:test].on :privmsg do
  case params[1] 
  when $correct_response
    puts "Correct response."
  else
    puts "Nope. Got #{params[1]} but expected #{$correct_response}"
  end
end # end on :privmsg

@bot.connect
#end # end thread

#bot.join
