# encoding: utf-8
require 'fileutils'
require 'uri'
require 'net/https'
require 'base64'
require 'ansirc'
require 'linguist/file_blob'
require 'rubyheap'

class Sandbox
  attr_accessor :time, :path, :home, :extension, :script_filename, :evaluate_with, :timeout, :owner, :includes, :code, :output_limit, :pastebin_after_limit, :pastebin_credentials, :binaries_must_exist, :stdin, :code_from_stdin, :skip_preceding_lines, :alter_code, :alter_result, :size_limit, :sandbox_net_t

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
    @timeout              = (options[:timeout] || 5).to_i
    @owner                = options[:owner] || 'anonymous'
    @includes             = options[:includes] || []
    @code                 = "#{options[:before]}#{options[:code]}#{options[:after]}"
    @output_limit         = options[:output_limit] || 2
    @pastebin_after_limit = options[:pastebin_after_limit] || true
    @pastebin_credentials = options[:pastebin_credentials] || {}
    @binaries_must_exist  = options[:binaries_must_exist] || [@evaluate_with.first]
    @stdin                = options[:stdin] || nil
    @code_from_stdin      = options[:code_from_stdin] || false
    @skip_preceding_lines = options[:skip_preceding_lines] || 0
    @skip_ending_lines    = options[:skip_ending_lines] || 0
    @alter_code           = options[:alter_code] || nil
    @alter_result         = options[:alter_result] || nil
    @size_limit           = options[:size_limit] || 10240 # bytes
    @sandbox_net_t        = options[:sandbox_net_t] || false

    # @alter_code is a method that gets called on @code immediately after a
    # Sandbox object is created.
    @code = @alter_code.call(@code) unless @alter_code.nil?
  end

  # Public: Set up the initial directory structure required for performing an
  #         evaluation. This is not part of the constructor because we want to
  #         allow for creating instances of Sandbox (e.g. to run tests) without
  #         actually doing anything.
  def initialize_directories
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
    sandbox_type = @sandbox_net_t ? 'sandbox_net_t' : 'sandbox_x_t'
    popen_args = [
      'timeout', @timeout.to_s,
      'sandbox', '-H', @home, '-T', "#{@home}/tmp/", '-t', "#{sandbox_type}",
      'timeout', @timeout.to_s, *@evaluate_with
    ]
    popen_args << @script_filename unless @code_from_stdin
    IO.popen(popen_args + [{:err => [:child, :out]}], 'w+') { |io|
      io.write File.read("#{@home}/#{@script_filename}") if @code_from_stdin
      io.write @stdin unless @stdin.nil?
      io.close_write
      @result = io.read(@size_limit)
      break unless @result
      break if (@no_output = @result.gsub("\n", "") == "")
      @result = @result.split("\n")
      @result.shift if @result[0].start_with? 'WARNING: Policy would be downgraded'
      @result = @result[@skip_preceding_lines..-(@skip_ending_lines + 1)].join("\n")
    }

    exitcode = $?.exitstatus.to_i

    if @result.nil? || @result.empty? || @no_output
      @result = "No output. (return code was #{exitcode})"
    end

    # Do we need to do anything to the result before we show it?
    @result = @alter_result.call(@result) unless @alter_result.nil?
    
    lines, output = @result.split("\n"), []
    if lines.any? { |l| l.length > 255 }
      output << "<output is long> #{pastebin(@pastebin_credentials)}"
    else
      @output_limit += 1 if lines.size == @output_limit + 1
      lines[0...@output_limit].each do |line|
        output << ANSIRC.to_irc(line)
      end
      if lines.count > @output_limit and @pastebin_after_limit
        output << pastebin(@pastebin_credentials)
      end
    end
    if exitcode == 124
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

  # Public: Pastebins the result of a code evaluation.
  #
  # This is used when the output of an evaluation is too long for IRC. The
  # full result is pastebinned.
  #
  # credentials - An optional Hash containing two keys, :username, and :password
  #               which, if present, are used to authenticate with the pastebin,
  #               to have the given account own the paste.
  #
  # Returns a String containing link to the paste, or an error message stating
  #   why we couldn't get it.
  def pastebin(credentials = {})
    username = credentials[:username] || nil
    password = credentials[:password] || nil

    heap = Refheap::Paste.new(username, password)

    input = File.open("#{@home}/#{@script_filename}").read
    language = Linguist::FileBlob.new("#{@home}/#{@script_filename}").language.name
    paste = "Input (#{@script_filename}):\n#{input}\n\nOutput:\n#{@result}"
    paste = heap.create(paste, :language => language, :private => true)

    "Output truncated: #{paste['url']} (#{@result.lines.count} lines of total output)"
  end

  # Public: Checks to make sure all needed binaries to perform an evaluation
  #         (@binaries_must_exist) exist and are located in a directory that
  #         is in $PATH.
  #
  # Returns false if a needed binary doesn't exist, and true if they all do.
  def binaries_all_exist?
    @binaries_must_exist.each do |binary|
      next if File.exists? binary
      return false unless ENV['PATH'].split(':').any? { |path| File.exists? File.join(path, '/', binary) }
    end
    true
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
