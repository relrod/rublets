%w{commands handlers server user message connection}.each { |x| load File.join(File.dirname(__FILE__), "#{x}.rb") }

module Rubino
  class Bot
    def initialize(opts)
      opts[:nick] ||= 'rubino'
      @nick = opts[:nick]
      @config = opts
      @last = nil
      @server = Server.new(opts[:server], opts[:port])
    end

    def command
      load File.join(File.dirname(__FILE__), 'commands.rb')
      @commands ||= Commands.new
      words = @last.words

      return unless words[0] =~ /^#{@nick}.$/

      i = words.length-1
      command = words[1..i].join('_').downcase
      until @commands.respond_to?(command) || i < 1
        i -= 1
        command = words[1..i].join('_').downcase
      end

      if @commands.respond_to?(command)
        rest = words[(i+1)..-1]
        response = @commands.instance_eval { __send__(command, @last, *rest) }
        if response.is_a?(Array) && response[0] == :noprefix
          response[1..-1]
        else
          "#{@last.sender.nick}: #{response}"
        end
      end
    end

    def raw(*args)
      args.each do |line|
        puts ">> #{line}\r\n"
        @connection.puts line
      end
    end

    def send(*args)
      raw "#{args[0].upcase} #{args[1]} :#{args[2..-1].join(' ')}"
    end

    def privmsg(recip, *args)
      send "PRIVMSG", recip, *args
    end

    def notice(recip, *args)
      send "NOTICE", recip, *args
    end

    def ctcp(recip, type, *args)
      privmsg recip, "\001#{type.to_s.upcase}", *args, "\001"
    end

    def action(recip, *args)
      ctcp :action, *args
    end

    def reply(*args)
      privmsg @last.recip, *args
    end

    def react(*args)
      action @last.recip, *args
    end

    def join(*args)
      send :join, args.join(',')
    end

    def connect
      @connection = Connection.new(@server)
      raw "USER #{@config[:nick]} * * :Rubino IRC bot", "NICK #{@config[:nick]}"
    end

    def handle(message)
      @handler ||= Handlers.new(self, @config)
      @handler.handle(message)
    end

    def parse(line)
      message = Message.new(line)
      @last = message
      if message.sender.nil?
        puts line
      else
        puts "[#{message.recip}/#{message.type}] <#{message.sender.nick}> #{message.text}"
      end
      handle(message)
    end

    def run
      until @connection.eof
        line = @connection.readline
        parse line
      end
    end

  end # class Bot
end   # module Rubino
