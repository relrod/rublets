require 'fileutils'

class Sandbox
  attr_accessor :time, :path, :home, :extension, :script_filename, :evaluate_with, :timeout, :owner, :includes, :code, :output_limit, :gist_after_limit, :binaries_must_exist, :stdin, :code_from_stdin, :skip_preceding_lines, :alter_code, :size_limit

  def initialize(options = {})
    unless ENV['PATH'].split(':').any? { |path| File.exists? path + '/sandbox' }
      raise "The `sandbox` executable does not exist and is required."
    end

    unless ENV['PATH'].split(':').any? { |path| File.exists? path + '/timeout' }
      raise "The `timeout` executable does not exist and is required. (Is coreutils installed?)"
    end

    @time                 = Time.now
    @path                 = options[:path]
    @home                 = options[:home] || "#{@path}/sandbox_home-#{@time.to_f}"
    @extension            = options[:extension] || "txt"
    @script_filename      = options[:script] || "#{@time.to_f}.#{@extension}"
    @evaluate_with        = options[:evaluate_with]
    @timeout              = options[:timeout].to_i || 5
    @owner                = options[:owner] || 'anonymous'
    @includes             = options[:includes] || []
    @code                 = "#{options[:before]}#{options[:code]}#{options[:after]}"
    @output_limit         = options[:output_limit] || 3
    @gist_after_limit     = options[:gist_after_limit] || true
    @binaries_must_exist  = options[:binaries_must_exist] || [@evaluate_with.first]
    @stdin                = options[:stdin] || nil
    @code_from_stdin      = options[:code_from_stdin] || false
    @skip_preceding_lines = options[:skip_preceding_lines] || 0
    @alter_code           = options[:alter_code] || nil
    @size_limit            = options[:size_limit] || 2048 # bytes

    # @alter_code is a method that gets called on @code immediately after a
    # Sandbox object is created.
    @code = @alter_code.call(@code) unless @alter_code.nil?

    FileUtils.mkdir_p @home
    FileUtils.mkdir_p "#{@path}/evaluated"
    FileUtils.mkdir_p "#{@home}/tmp"
  end

  def mkdir(directory)
    FileUtils.mkdir_p "#{@home}/#{directory}"
  end

  def copy(source, destination)
    FileUtils.cp_r source, "#{@home}/#{destination}"
  end

  def evaluate
    return ["One of (#{@binaries_must_exist.join(', ')}) was not found in $PATH. Try again later."] unless binaries_all_exist?
    insert_code_into_file
    copy_audit_script
    cmd_script_filename = @code_from_stdin ? [] : [@script_filename]
    popen_args = [
      'timeout', @timeout.to_s,
      'sandbox', '-H', @home, '-T', "#{@home}/tmp/", '-t', 'sandbox_x_t',
      'timeout', @timeout.to_s, *@evaluate_with
    ]
    popen_args << @script_filename unless @code_from_stdin
    IO.popen([*popen_args, :err => [:child, :out]], 'w+') { |io|
      io.write File.read("#{@home}/#{@time.to_f}.#{@extension}") if @code_from_stdin
      io.write @stdin unless @stdin.nil?
      io.close_write
      @result = io.read(@size_limit).split("\n")
      @result = "An error occurred processing the code you specified, but no error was returned" if @result == nil
      @result.shift if @result[0].start_with? 'WARNING: Policy would be downgraded'
      @result = @result[@skip_preceding_lines..-1].join("\n")
    }
    if $?.exitstatus.to_i == 124
      @result = "Timeout of #{@timeout} seconds was hit."
    elsif @result.nil? or @result.empty?
      @result = "No output." 
    end
    
    lines, output = @result.split("\n"), []
    if lines.any? { |l| l.length > 255 }
      output << "<output is long> #{gist}"
    else
      lines[0...@output_limit].each do |line|
        output << line
      end
      if lines.count > @output_limit and @gist_after_limit
        output << "<output truncated> #{gist}"
      end
    end
    output
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
          "input.#{@extension}" => {
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
    FileUtils.cp("#{@home}/#{@script_filename}", "#{@path}/evaluated/#{@time.year}-#{@time.month}-#{@time.day}_#{@time.hour}-#{@time.min}-#{@time.sec}-#{@owner}-#{@time.to_f}.#{@extension}")
  end

  def binaries_all_exist?
    @binaries_must_exist.each do |binary|
      return false unless ENV['PATH'].split(':').any? { |path| File.exists? File.join(path, '/', binary) }
    end
    true
  end

  def insert_code_into_file
    File.open("#{@home}/#{@time.to_f}.#{@extension}", 'w') do |f|
      f.puts @code
    end
  end

end
