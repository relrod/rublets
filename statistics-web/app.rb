require "rubygems"
require "bundler/setup"
require "sinatra"
require "language_sniffer"

$: << File.dirname(__FILE__)
require "extra_languages"

$: << File.join(File.dirname(__FILE__), '..')
require "eval/config"

get '/' do
  evaluated_path = File.join(Configru.rublets_home, 'evaluated', '*')
  puts evaluated_path
  @languages = Hash.new { |h,k| h[k] = 0 }
  @users = Hash.new { |h,k| h[k] = 0 }
  Dir[evaluated_path].each do |file|
    user = file.split('-')[5]
    language = LanguageSniffer.detect("#{file}").language
    puts file if language.nil?
    language.nil? ? @languages['unknown'] += 1 : @languages[language.name] += 1
    @users[user] += 1
  end
  erb :index
end
