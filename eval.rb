require 'fileutils'

class Sandbox
  attr_accessor :time, :path, :home, :script_filename, :evaluate_with, :timeout, :includes

  def initialize(options = {})
    unless ENV['PATH'].split(':').any? { |path| File.exists? path + '/sandbox' }
      raise "The `sandbox` executable does not exist and is required."
    end
    
    unless ENV['PATH'].split(':').any? { |path| File.exists? path + '/timeout' }
      raise "The `timeout` executable does not exist and is required. (Is coreutils installed?)"
    end
    
    @time = Time.now
    @path = options[:path]
    @home = options[:home] || "#{@path}/sandbox_home-#{@time.to_f}"
    @script_filename = options[:script]
    @evaluate_with = options[:evaluate_with]
    @timeout = options[:timeout].to_i
    @includes = options[:includes] || []

    FileUtils.mkdir_p @home
  end

  def mkdir(directory)
    FileUtils.mkdir_p "#{@home}/#{directory}"
  end

  def copy(source, destination)
    FileUtils.cp_r source, "#{@home}/#{destination}"
  end

  def evaluate
    copy_audit_script
    IO.popen(['sandbox', '-H', @home, '-T', "#{@path}/tmp/", '-t', 'sandbox_x_t', 'timeout', @timeout.to_s, @script_filename, {:err => [:child, :out]}, *@evaluate_with]) { |stdout|
      @result = stdout.read
    }
    if $?.exitstatus.to_i == 124
      @result = "Timeout of #{@timeout} seconds was hit."
    elsif @result.empty?
      @result = "No output." 
    end
    @result
  end

  def rm_home!
    FileUtils.rm_rf @home
  end

  def gist
    gist = URI.parse('https://api.github.com/gists')
    http = Net::HTTP.new(gist.host, gist.port)
    http.use_ssl = true
    response = http.post(gist.path, {
        'public' => false,
        #'description' => "#{nickname}'s ruby eval",
        'files' => {
          'input.rb' => {
            'content' => File.open("#{@home}/#{@script_filename}").read
          },
          'output.txt' => {
            'content' => @result
          }
        }
      }.to_json)
    if response.response.code.to_i != 201
      return "Unable to Gist output."
    else
      JSON(response.body)['html_url']
    end
  end

  private
  def copy_audit_script
    FileUtils.cp("#{@home}/#{@script_filename}", "#{@path}/evaluated/#{@script_filename}")
  end

end
