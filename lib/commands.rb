load File.join(File.dirname(__FILE__), 'safeeval.rb')

module Rubino
  class Commands
    attr_accessor :message
    def initialize(irc=nil, config=nil)
      @irc = irc
      @config = config
      @commands = Hash.new(0)
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

      return unless words[0] =~ /^#{@irc.self.nick}.?$/

      i = words.length-1
      command = words[1..i].join('_').upcase
      until @commands.include?(command) || i < 1
        i -= 1
        command = words[1..i].join('_').upcase
      end

      if @commands.include?(command)
        @irc.args = words[(i+1)..-1]
        block = @commands[command]
        begin
          @irc.instance_eval &block
        rescue => e
          puts "----------------------------------------------------"
          puts "Error running command \"#{command}\", details below:"
          puts e
          puts "----------------------------------------------------"
          @irc.reply_highlight "Error running command \"#{command}\"."
        end
      end   # if @commands.respond_to?(command)
    end

    def command(name, &block)
      @commands[name.to_s.upcase] = block
    end

    def set_defaults
      command :commands do
        reply_highlight Commands.new.names.join(', ')
      end
    
      command :about do
        reply "Information about the rubino IRC bot is at http://duckinator.net/rubino"
      end

      command :source do
        reply "I'm written in ruby by duckinator. You can find my source at http://github.com/RockerMONO/rubino"
      end

      command :eval do
        # Ruby safe eval! WOOHOO!
        sender = last.sender.nick
        recip = last.recip
        chroot = File.join(File.dirname(__FILE__), "..", "tmp")
        filename = File.join(chroot, "#{sender}-#{Time.now}.rb".gsub(' ', '_'))

        Thread.new(sender, recip, chroot, filename) do |sender, recip, chroot, filename|
          first, second, code = last.text.split(' ', 3)
          result = SafeEval.new(chroot).run(code, filename)
          result = "(No output)" if result.empty?

          lines = result.split("\n")

          limit = 2

          lines[0...limit].each do |line|
            privmsg recip, "#{sender}: #{line}"
          end
        end
      end
    end # set_defaults

    def set_custom
    end
  end   # class Commands
end     # module Rubino
