module Rubino
  class Commands
    attr_accessor :message
    def initialize(irc, config)
      @irc = irc
      @config = config
      @commands = Hash.new(0)
      @ctcps = Hash.new(0)
      set_defaults
      set_custom
      handle(@irc.last)
    end

    def handle(message)
      words = message.words

      return unless words[0] =~ /^#{@irc.nick}.?$/

      i = words.length-1
      command = words[1..i].join('_').upcase
      until @commands.include?(command) || i < 1
        i -= 1
        command = words[1..i].join('_').upcase
      end

      if @commands.include?(command)
        @irc.args = words[(i+1)..-1]
        block = @commands[command]
        @irc.instance_eval &block
      end   # if @commands.respond_to?(command)
    end

    def command(name, &block)
      @commands[name.to_s.upcase] = block
    end

    def set_defaults
      command :commands do
        self.class.instance_methods(false).map do |x|
          # We don't want to mention the .message and .message= methods
          if x.to_s.gsub('=','') != 'message'
            x.to_s.gsub('_', ' ')
          end
        end.delete_if(&:nil?).join(', ')
      end
    
      command :about do
        reply "Information about the rubino IRC bot is at http://duckinator.net/rubino"
      end

      command :source do
        reply "I'm written in ruby by duckinator. You can find my source at http://github.com/RockerMONO/rubino"
      end
    end # set_defaults

    def set_custom
    end
  end   # class Commands
end     # module Rubino
