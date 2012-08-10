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

  ([language] + values[:aliases]).compact.each do
    next unless needed
    undocumented << language
    needed = false
  end
end

exitcode = 0

if undocumented.empty?
  puts "[PASS] All languages are documented!"
else
  puts "[FAIL] The following languages seem undocumented!"
  undocumented.each { |language| puts "  - #{language}" }
  exitcode = 1
end

language_keys = Language::languages.keys - Configru.special_languages
if language_keys != language_keys.sort
  puts "[FAIL] The hash of languages in eval/languages.rb should be sorted."
  exitcode = 1
else
  puts "[PASS] The hash of languages in eval/languages.rb is sorted."
end

exit exitcode
