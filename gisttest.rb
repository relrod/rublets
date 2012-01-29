#!/usr/bin/env ruby
require 'net/https'
require 'uri'
require 'pp'
require 'json'

gist = URI.parse('https://api.github.com/gists')
http = Net::HTTP.new(gist.host, gist.port)
http.use_ssl = true

pp http.post(gist.path, {
  'public' => false,
  'description' => 'Foo Bar Baz',
  'files' => {
    'input.rb' => {
      'content' => "This is my file. There are many like it."
    },
    'output.txt' => {
      'content' => "but this one is mine."
    }
  }
}.to_json).response.code.to_i
