require 'fileutils'
require 'uri'
require 'net/https'
require 'base64'
require 'ansirc'

class Sandbox
  attr_accessor :time, :path, :home, :extension, :script_filename, :evaluate_with, :timeout, :owner, :includes, :code, :output_limit, :gist_after_limit, :github_credentials, :binaries_must_exist, :stdin, :code_from_stdin, :skip_preceding_lines, :alter_code, :size_limit

  # Public: Creates a Sandbox instance.
  #
  # options - A Hash which contains any number of options for tweaking how code
  #           is evaluated.
  #
  # Returns the new instance of Sandbox, after making necessary directories to
  #   proceed with an evaluation.
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
    @script_filename      = options[:script_filename] || "#{@time.to_f}.#{@extension}"
    @evaluate_with        = options[:evaluate_with]
    @timeout              = options[:timeout].to_i || 5
    @owner                = options[:owner] || 'anonymous'
    @includes             = options[:includes] || []
    @code                 = "#{options[:before]}#{options[:code]}#{options[:after]}"
    @output_limit         = options[:output_limit] || 3
    @gist_after_limit     = options[:gist_after_limit] || true
    @github_credentials   = options[:github_credentials] || {}
    @binaries_must_exist  = options[:binaries_must_exist] || [@evaluate_with.first]
    @stdin                = options[:stdin] || nil
    @code_from_stdin      = options[:code_from_stdin] || false
    @skip_preceding_lines = options[:skip_preceding_lines] || 0
    @skip_ending_lines    = options[:skip_ending_lines] || 0
    @alter_code           = options[:alter_code] || nil
    @size_limit           = options[:size_limit] || 2048 # bytes

    # @alter_code is a method that gets called on @code immediately after a
    # Sandbox object is created.
    @code = @alter_code.call(@code) unless @alter_code.nil?

    FileUtils.mkdir_p @home
    FileUtils.mkdir_p "#{@path}/evaluated"
    FileUtils.mkdir_p "#{@home}/tmp"
  end

  # Public: Creates a directory in the Sandbox. Can create directories and their
  #         parent directories (similar to `mkdir -p`).
  #
  # directory - The name (or path) of the directory to create, relative to the
  #             home directory of the Sandbox.
  #
  # Returns the output of FileUtils.mkdir_p (an Array containing one element,
  #   the name of the directory we just created.)
  def mkdir(directory)
    FileUtils.mkdir_p "#{@home}/#{directory}"
  end

  # Public: Copies a file into the sandbox.
  #
  # source      - A String containing a path to the original file that we want
  #               to copy. Relative to the directory containing rublets.rb. This
  #               can optionally be an Array of Strings.
  # destination - A String containing the path to place the copy, relative to
  #               the home directory of the sandbox.
  #
  # Returns nothing.
  def copy(source, destination)
    FileUtils.cp_r source, "#{@home}/#{destination}"
  end

  # Public: Performs an actual evaluation.
  #
  # This is the method that actually performs an evaluation within the Sandbox,
  # using the information contained in the Hash that was passwd instance of
  # Sandbox was created.
  #
  # Returns a String containing the result of the evaluation, or any errors that
  #   occurred while trying to evaluate.
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
    IO.popen(popen_args + [{:err => [:child, :out]}], 'w+') { |io|
      io.write File.read("#{@home}/#{@script_filename}") if @code_from_stdin
      io.write @stdin unless @stdin.nil?
      io.close_write
      @result = io.read(@size_limit).split("\n")
      @result = "An error occurred processing the code you specified, but no error was returned" if @result == nil
      @result.shift if @result[0].start_with? 'WARNING: Policy would be downgraded'
      @result = @result[@skip_preceding_lines..-(@skip_ending_lines + 1)].join("\n")
    }

    if @result.nil? or @result.empty?
      @result = "No output." 
    end

    # Fix a Ruby 1.9-specific encoding bug in which causes incomplete IO chunks
    # to be encoded as ASCII-8BIT. Thanks to the opscode/ohai folks, which this
    # fix comes from. See http://git.io/mqTfLg for more info (their fix).
    if "".respond_to?(:force_encoding) && defined?(Encoding)
      @result = @result.force_encoding(Encoding.default_external)
    end
    
    lines, output = @result.split("\n"), []
    if lines.any? { |l| l.length > 255 }
      output << "<output is long> #{gist(@github_credentials)}"
    else
      @output_limit += 1 if lines.size == @output_limit + 1
      lines[0...@output_limit].each do |line|
        output << ANSIRC.to_irc(line)
      end
      if lines.count > @output_limit and @gist_after_limit
        output << "<output truncated> #{gist(@github_credentials)}"
      end
    end
    if $?.exitstatus.to_i == 124
      output << "Timeout of #{@timeout} seconds was hit."
    end
    output
  end

  # Public: Forcibly removes the Sandbox instance's home directory.
  #
  # Returns nothing.
  def rm_home!
    FileUtils.rm_rf @home
  end

  # Public: Gists (https://gist.github.com/) the result of a code evaluation.
  #
  # This is used when the output of an evaluation is too long for IRC. The
  # full result is pastebinned using Gist.
  #
  # credentials - An optional Hash containing two keys, :username, and :password
  #               which, if present, are used to authenticate with Github, to
  #               have the given account own the Gist.
  #
  # Returns a String containing link to the Gist, or an error message stating
  #   why we couldn't get it.
  def gist(credentials = {})
    username = credentials[:username] || nil
    password = credentials[:password] || nil

    gist = URI.parse('https://api.github.com/gists')
    http = Net::HTTP.new(gist.host, gist.port)
    http.use_ssl = true
    
    headers = {}
    headers['Authorization'] = 'Basic ' + Base64.encode64("#{username}:#{password}").chop unless username.nil? or password.nil?
    
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
      }.to_json, headers)
    if response.response.code.to_i != 201
      return "Unable to Gist output."
    else
      JSON(response.body)['html_url']
    end
  end

  private

  # Internal: Copies evaluated code to someplace safe, for audit purposes.
  #
  # Before code is evaluated, Sandbox.evaluate() calls this to copy the code
  # to somewhere safe (@path/evaluated/*) for auditing purposes in case we ever
  # need to see what caused a bug. Not that Rublets has bugs. ;-)
  #
  # Returns nothing.
  def copy_audit_script
    FileUtils.cp("#{@home}/#{@script_filename}", "#{@path}/evaluated/#{@time.year}-#{@time.month}-#{@time.day}_#{@time.hour}-#{@time.min}-#{@time.sec}-#{@owner}-#{@time.to_f}.#{@extension}")
  end

  # Internal: Checks to make sure all needed binaries to perform an evaluation
  #           (@binaries_must_exist) exist and are located in a directory that
  #           is in $PATH.
  #
  # Returns false if a needed binary doesn't exist, and true if they all do.
  def binaries_all_exist?
    @binaries_must_exist.each do |binary|
      return false unless ENV['PATH'].split(':').any? { |path| File.exists? File.join(path, '/', binary) }
    end
    true
  end

  # Internal: Takes the code that we are about to evaluate, and actually puts it
  #           in the file, so that we can...evaluate it.
  #
  # Returns the File.
  def insert_code_into_file
    File.open("#{@home}/#{@script_filename}", 'w') do |f|
      f.puts @code
    end
  end

end
