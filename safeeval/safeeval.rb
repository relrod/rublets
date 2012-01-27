require 'stringio'
require 'rbconfig'
require 'fileutils'

$EXECUTABLE = File.join(RbConfig::CONFIG['bindir'], RbConfig::CONFIG['ruby_install_name'])

class SafeEval
  def self.setup(timelimit=5, memlimit=10)
    @@timelimit = timelimit
    @@memlimit = memlimit
    @@memlimit = 39 # FIXME
    @@chroot = File.join(File.dirname(__FILE__), '..', 'tmp')
    
    # Purge existing chroot
    FileUtils.rm_rf(@@chroot) if File.directory?(@@chroot)
    
    # Create new chroot
    Dir.mkdir(@@chroot)
  end
  
  def self.run(code, nick)
    filename = File.join(@@chroot, "#{nick}-#{Time.now.to_f}.rb")
    
    File.open(filename, "w") do |f|
      f.write(generate_script(code))
    end
    
    begin
      `sudo #{$EXECUTABLE} #{filename.inspect}`
    rescue Exception => e
      "#{e.class}: #{e.message}"
    end
  end

  def self.generate_script(code)
      tmp = <<-EOF
require 'stringio'
require 'etc'
require 'timeout'

trap("XCPU") do
  puts "Execution took longer than #{@timelimit} seconds, exiting."
  exit!
end

nobody_uid = Etc.getpwnam('nobody').uid
nobody_gid = Etc.getgrnam('nobody').gid
Dir.chroot(#{@@chroot.inspect})
Dir.chdir("/")

# RAM limit
Process.setrlimit(Process::RLIMIT_AS, #{@@memlimit}*1024*1024)

# CPU time limit
Process.setrlimit(Process::RLIMIT_CPU, #{@@timelimit+1})

Process.initgroups('nobody', nobody_gid)
Process::GID.change_privilege(nobody_gid)
Process::UID.change_privilege(nobody_uid)

if Process.uid != nobody_uid
  puts "Error setting up chroot"
  exit
end

output_io = nil
output    = ''
result    = ''
error     = nil

begin
  Timeout.timeout(5) do
    output_io = $stdout = $stderr = StringIO.new
    code = "$SAFE = 3; BEGIN { $SAFE=3 };" + #{code.inspect}

    result = ::Kernel.eval(code, TOPLEVEL_BINDING)
  end
rescue Exception => e
  $stdout = STDOUT
  $stderr = STDERR
  puts "\#{e.class}: \#{e.message}"
  exit
ensure
  $stdout = STDOUT
  $stderr = STDERR
end

output = output_io.string

if output.empty?
  puts result.inspect
else
  puts output
end
      EOF
      tmp
  end
end
