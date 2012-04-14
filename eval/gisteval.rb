#!/usr/bin/env ruby
require 'uri'
require 'net/http'
require 'net/https'
require 'json'

$LOAD_PATH.unshift File.dirname(__FILE__)
require 'config'

class GistEval

  # Public: Evaluate a given Gist link.
  #
  # Take a Gist link, do a quick check to see if we can evaluate it, then
  # evaluate it and return the result.
  #
  # gist_url - A String which is a URL pointing to a Gist.
  #
  # Returns a String containing the output of the evaluation.
  def evaluate(gist_url, file = nil)
    uri = URI(gist_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')
    request = Net::HTTP::Get.new uri.request_uri
    response = http.request(request)
    json = JSON(response.body)
    
    if file.nil? and json['files'].size > 1
      return "<multiple files in gist, specify file to evaluate>"
    end

    # To be continued.
    
  end
end
