require "rubygems"
require "bundler/setup"
require "sinatra"
require "language_sniffer"

$: << File.dirname(__FILE__)
require "extra_languages"

$path = '/home/ricky/.rublets/evaluated'

get '/' do
  @languages = Hash.new { |h,k| h[k] = 0 }
  @users = Hash.new { |h,k| h[k] = 0 }
  Dir[$path + '/*'].each do |file|
    user = file.split('-')[5]
    language = LanguageSniffer.detect("#{file}").language
    puts file if language.nil?
    language.nil? ? @languages['unknown'] += 1 : @languages[language.name] += 1
    @users[user] += 1
  end
  erb :index
end
