#!/usr/bin/env ruby
# Goes through and makes sure all languages in the map are documented in the README.md.

require 'nokogiri'

$LOAD_PATH.unshift File.dirname(__FILE__)
require 'eval/eval'
require 'eval/config'
require 'eval/languages'

def sanitize_language(lang_string)
  lang_string.downcase.gsub(' ', '').gsub(/\(.*/, '')
end

readme = Nokogiri::HTML(File.open(File.dirname(__FILE__) + '/README.md'))
documented_languages = readme.css('table a').collect { |link| sanitize_language(link.content) }

undocumented = []
Language.languages.each do |language, values|
  language = sanitize_language(language)
  needed = true
  values[:aliases] = [] if values[:aliases].nil?
  next unless (documented_languages & ([language] + values[:aliases]).compact).empty?

  ([language] + values[:aliases]).compact.each do |l|
   # next if documented_languages.include? l
    next unless needed
    undocumented << language
    needed = false
  end
end

if undocumented.empty?
  puts "[PASS] All languages are documented!"
  exit 0
else
  puts "[FAIL] The following languages seem undocumented!"
  undocumented.each { |language| puts "  - #{language}" }
  exit 1
end
