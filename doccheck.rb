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

# Construct a hash of {'lang_name' => ['all', 'aliases']}
mapped_languages = {}
Language.languages.keys.each do |language|
  mapped_languages[language] = (Language.by_name(language)[:aliases].to_a + [language]).collect { |l| sanitize_language(l) }
end

readme = Nokogiri::HTML(File.open(File.dirname(__FILE__) + '/README.md'))
documented_languages = readme.css('table a').collect { |link| sanitize_language(link.content) }

undocumented = documented_languages - (mapped_languages.values.flatten & documented_languages)

if undocumented.empty?
  puts "[PASS] All languages are documented!"
  exit 0
else
  puts "[FAIL] The following languages seem undocumented!"
  undocumented.each { |language| puts "  - #{language}" }
  exit 1
end
