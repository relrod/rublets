require "rubygems"
require "bundler/setup"
require "sinatra"
require "linguist/file_blob"
require "backports"
require "time"
require "json"

$: << File.dirname(__FILE__)
require "extra_languages"

$: << File.join(File.dirname(__FILE__), '..')
require "eval/config"

get '/' do
  evaluated_path = File.join(Configru.rublets_home, 'evaluated', '*')

  @languages   = Hash.new { |h,k| h[k] = 0 }
  @users       = Hash.new { |h,k| h[k] = 0 }
  @evaluations = Hash.new { |h,k| h[k] = 0 }

  Dir[evaluated_path].each do |file|
    language = Linguist::FileBlob.new(file).language
    puts file if language.nil?
    language.nil? ? @languages['unknown'] += 1 : @languages[language.name] += 1

    user = file.split('-')[5]
    @users[user] += 1

    time = Time.parse(file.rpartition('-').first.rpartition('-').first)
    @evaluations[time] += 1
  end

  erb :index
end

statistics_dir = File.expand_path(File.dirname(__FILE__))
Dir.chdir('/opt/rublets')

[
  'apricot-lang/apricot',
].each do |name|
  if File.exists?(name)
    Dir.chdir(name)
    `git pull origin master`
  else
    owner, repo = name.split('/', 2)
    Dir.mkdir(owner)
    `git clone git://github.com/#{name}.git #{repo}`
  end
end

Dir.chdir(statistics_dir)

post '/rublets/pull' do
  push = JSON.parse(params[:payload])
  directory = "/opt/rublets/#{push['repository']['owner']['name']}/#{push['repository']['name']}"
  if File.exists?(directory)
    Dir.chdir(directory)
    `git pull origin master`
    Dir.chdir(statistics_dir)
  else
    puts "Whoopsie! An error occurred: The directory #{directory} was not found."
  end
end
