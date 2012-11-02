#!/usr/bin/env ruby
# Goes through all languages and makes sure that all needed binaries exist to
# evaluate code in it.

$LOAD_PATH.unshift File.dirname(__FILE__)
require 'eval/eval'
require 'eval/config'
require 'eval/languages'

missing_binaries = []

Language.languages.each do |language, values|
  if values[:special]
    missing_binaries << "[special] #{language}"
    next
  end

  sandbox = Sandbox.new(Language.by_name(language))
  if sandbox.binaries_all_exist?
    print '.'
    sleep 0.005
  else
    print '!'
    sleep 0.05
    missing_binaries << language
  end
end

puts

puts "Languages missing binaries:"
puts missing_binaries.join("\n")
