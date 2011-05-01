load File.join(File.dirname(__FILE__), '..', 'safeeval', 'safeeval.rb')
load File.join(File.dirname(__FILE__), '..', 'gist.rb')


module Rubino
  class Commands
    attr_accessor :message
    def initialize(irc=nil, config=nil)
      @irc = irc
      @config = config
      @commands = Hash.new(0)

      # Why must this be $chroot, instead of @chroot?
      # I'm not sure, but $chroot works and @chroot doesn't, in Thread.new{}
      # Saves two an IO-related function call on each `eval` usage
      $chroot = File.join(File.dirname(__FILE__), '..', 'tmp')

      set_defaults
      set_custom
      handle(@irc.last) if @irc
    end

    def inspect
      "{" + names.join("=>..., ") + "}"
    end

    def names
      @commands.map {|k,v| k.downcase.gsub('_', ' ') }
    end

    def handle(message)
      words = message.words

      return if words[0] !~ /^#{@irc.self.nick}.?$/ || words.length < 2

=begin
      # Removed for efficiency purposes. This is rather nasty.
      i = words.length-1
      command = words[1..i].join('_').upcase
      until @commands.include?(command) || i < 1
        i -= 1
        command = words[1..i].join('_').upcase
      end
=end

      command = words[1].downcase

      if @commands.include?(command)
        #@irc.args = words[(i+1)..-1]
        @irc.args = words[2..-1]
        block = @commands[command]
        begin
          @irc.instance_eval &block
        rescue => e
          puts '----------------------------------------------------'
          puts "Error running command \"#{command}\", details below:"
          puts e
          puts '----------------------------------------------------'
          @irc.reply_highlight "Error running command \"#{command.downcase}\": http://gist.github.com/#{gist('error' => e.to_s)[0]['repo']}"
        end
      end   # if @commands.respond_to?(command)
    end

    def command(name, &block)
      @commands[name.to_s.downcase] = block
    end

    def set_defaults
      command :commands do
        reply_highlight Commands.new.names.join(', ')
      end
    
      command :about do
        reply 'Information about the rubino IRC bot is at http://duckinator.net/rubino'
      end

      command :source do
        reply 'I\'m written in ruby by duckinator. You can find my source at http://github.com/duckinator/rubino'
      end

      command :eval do
        # Ruby safe eval! WOOHOO!
        Thread.new do
          _last = last.clone
          filename = File.join($chroot, "#{_last.sender.nick}-#{Time.now.to_f}.rb")
 
          first, second, code = _last.text.split(' ', 3)
          result = SafeEval.new($chroot).run(code, filename)
          result = '(No output)' if result.empty?

          lines = result.split("\n")

          limit = 2

          lines[0...limit].each do |line|
            privmsg _last.recip, "#{_last.sender.nick}: #{line}"
          end
        end
      end
    end # set_defaults

    def set_custom
    end
  end   # class Commands
end     # module Rubino
