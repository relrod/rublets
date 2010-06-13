module Rubino
  class Handlers
    def initialize(irc, config)
      @irc = irc
      @config = config
      @handlers = Hash.new(0)
      set_defaults
    end

    def handle(message)
      if !message.type.nil? && @handlers.include?(message.type.upcase)
        block = @handlers[message.type.upcase]
        @irc.instance_eval &block
      end
    end

    def on(name, &block)
      @handlers[name.to_s.upcase] = block
    end

    def set_defaults
      on '001' do
        join(@config['channels'])
      end

      on :privmsg do
        handle_command
      end

      on :ping do
        raw @last.full.gsub('PING ','PONG ')
      end
    end
  end # class Handlers
end   # module Rubino
