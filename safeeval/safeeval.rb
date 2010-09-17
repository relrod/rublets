require 'stringio'
require 'rbconfig'

$EXECUTABLE = File.join(RbConfig::CONFIG['bindir'], RbConfig::CONFIG['ruby_install_name'])

class SafeEval
  attr_reader :error
  def initialize(chroot=nil, timelimit=5, memlimit=10)
     @timelimit = timelimit
     @memlimit = memlimit
    unless chroot.nil?
      Dir.mkdir(chroot) if !File.directory?(chroot)
      @chroot = chroot
    end
  end

  def out_to_string(stdout=StringIO.new)
    begin
      $stdout = $stderr = stdout
      yield
    ensure
      $stdout = STDOUT
      $stderr = STDERR
    end
    stdout.string
  end

  def eval(cmd)
    output = nil
    result = nil
    command = <<-EOF
      $SAFE = 3
      BEGIN { $SAFE=3 }
      #{cmd}
    EOF

    begin
      result = ::Kernel.eval(command, TOPLEVEL_BINDING)
    rescue Exception => e
      @error = e
    end

    if !@error.to_s.empty?
      @error
    elsif !output.to_s.empty?
      output
    else
      result
    end
  end

  def run(code, filename, timelimit=nil, memlimit=nil)
    @timelimit = timelimit unless timelimit.nil?
    @memlimit = memlimit unless memlimit.nil?
    save_file(code, filename)
    run_file(filename)
  end

  def run_file(filename)
    random = nil
    output = ''

    begin
      thread = Thread.new do
        random = rand
        output = `sudo #{$EXECUTABLE} #{filename.inspect} #{random}`
      end
    rescue Exception => e
      error = e
    end

    1.upto(@timelimit+1).each do |i|
      id = nil
      id_parts = `ps aux | grep -v grep | grep -i #{$EXECUTABLE} | grep -i nobody | grep -i "#{random}"`.split(' ')
      id = id_parts[1].to_i unless id_parts.include?("<defunct>")

      if thread.alive? && i >= @timelimit && id != 0
        `sudo kill -XCPU #{id}`
        break
      elsif i > @timelimit || !thread.alive?
        break
      else
        sleep 1
      end
    end

    if !error.nil?
      error
    elsif !output.inspect.empty? && (output.inspect != '""' && !thread.value.inspect.empty?)
      output
    else
      thread.value
    end
  end

  def save_file(code, filename)
    File.open(filename, "w") do |f|
      f.write(generate_script(code))
    end
  end

  def generate_script(code)
      tmp = open(File.join(File.dirname(__FILE__), 'template.rb')).read
      keywords = {
                   :time      => Time.now.to_s,
                   :file      => __FILE__.inspect,
                   :timelimit => @timelimit.to_s,
                   :memlimit  => @memlimit.to_s,
                   :chroot    => @chroot.inspect,
                   :code      => code.inspect[1..-2].inspect # Until we find a nicer fix
                 }
      keywords.map do |k, v|
        tmp.gsub!("%#{k.to_s}%", v)
      end
      tmp
  end
end
