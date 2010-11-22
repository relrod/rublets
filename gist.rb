require 'net/http'
require 'uri'
require 'json'

def gist(data)
  data = { "file" => data } if data.is_a?(String)

  files = {}
  data.length.times do |i|
    files["files[#{data.keys[i]}]"] = data[data.keys[i]]
  end
  JSON.parse(Net::HTTP.post_form(URI.parse('http://gist.github.com/api/v1/json/new'), files).body)['gists']
end
