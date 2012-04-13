require 'configru'

$LOAD_PATH.unshift File.dirname(__FILE__)
require 'languages'

Configru.load do
  just 'rublets.yml'
  
  defaults do
    servers {}
    nickname 'rublets'
    comchar '!'
    default_ruby 'ruby-1.9.3-p0'
    version_command 'rpm -qf'
    special_languages [
      'lolcode',
      'ruby (see !rubies)',
    ]
  end

  verify do
    nickname /^[A-Za-z0-9_\`\[\{}^|\]\\-]+$/
  end
end

# Append special cased languages to Language.languages
Configru.special_languages.each do |language|
  Language.languages[language] = { :special => true }
end
