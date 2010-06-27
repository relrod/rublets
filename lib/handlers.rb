require File.join(File.dirname(__FILE__), 'commands.rb')

module Rubino
  class Handlers
    def initialize(irc, config)
      @irc = irc
      @config = config
      @handlers = Hash.new(0)
      @ctcps = Hash.new(0)
      set_defaults
      set_custom
    end

    def inspect
      "#<Rubino::Handlers handlers={'" + handler_names.join("'=>..., '") + "'=>...}, ctcps={'" + ctcp_names.join("'=>..., '") + "'=>...}>"
    end

    def handler_names
      @handlers.map {|k,v| k.downcase.gsub('_', ' ') }
    end

    def ctcp_names
      @ctcps.map {|k,v| k.downcase.gsub('_', ' ') }
    end

    def handle(message)
      set_custom
      block = @handlers["UNKNOWN"]
      if !message.type.nil?
        if message.type == "CTCP" && @ctcps.include?(message.ctcp_type.upcase)
          block = @ctcps[message.ctcp_type.upcase]
        elsif @handlers.include?(message.type.upcase)
          block = @handlers[message.type.upcase]
        end
      end
      if block.is_a?(Proc)
        @irc.instance_eval &block
      end
    end

    def on(name, &block)
      @handlers[name.to_s.upcase] = block
    end

    def on_ctcp(name, &block)
      @ctcps[name.to_s.upcase] = block
    end

    def set_defaults
      on '001' do
        join(@config['channels'])
        if @config.include?('password')
          privmsg :NickServ, "identify #{@config['password']}"
        end
      end

      on :privmsg do
        Commands.new(@config)
      end

      on :ping do
        raw last.full.gsub('PING ','PONG ')
      end

      on '433' do
        if @config['nicks'].size >= @nick_number
          @nick_number += 1
          puts "NOTICE: Changing nick from #{@nick} to #{@config['nicks'][@nick_number]}"
          nick= @config['nicks'][@nick_number]
        end
      end

      on :unknown do
        puts last
      end

      on_ctcp :ping do
        ctcp_reply :ping, last.text
      end

    end

    def set_custom
      # Custom handlers here
    end
  end # class Handlers
end   # module Rubino
