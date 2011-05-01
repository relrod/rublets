load File.join(File.dirname(__FILE__), 'commands.rb')

module Rubino
  class Handlers
    attr_reader :handlers
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
      @handlers.map {|k,v| k }
    end

    def ctcp_names
      @ctcps.map {|k,v| k }
    end

    def handle(message)
      if !message.type.nil?
        if message.type == 'CTCP' && @ctcps.include?(message.ctcp_type)
          puts "[#{message.recip}] #{message.sender.nick}: CTCP #{message.ctcp_type} #{message.text}"
          ctcp_blocks = @ctcps[message.ctcp_type]
        end

        if @handlers.include?(message.type)
          blocks = @handlers[message.type]
        else
          blocks = @handlers['UNKNOWN']
        end

        # Run applicable blocks
        begin
          if blocks.is_a?(Array)
            blocks.each do |block|
              @irc.instance_eval &block if block.is_a?(Proc)
            end
          end
        rescue => e
          puts '----------------------------------------------------'
          puts "Error running handler for \"#{message.type}\", details below:"
          puts e
          puts '----------------------------------------------------'
        end

        begin
          if ctcp_blocks.is_a?(Array)
            ctcp_blocks.each do |ctcp_block|
              @irc.instance_eval &ctcp_block if ctcp_block.is_a?(Proc)
            end
          end
        rescue => e
          puts '----------------------------------------------------'
          puts "Error running CTCP handler for \"#{message.type}\", details below:"
          puts e
          puts '----------------------------------------------------'
        end
      end
    end

    def on(name, &block)
      name = name.to_s.downcase
      @handlers[name] = [] unless @handlers.include?(name)
      n = @handlers[name].size
      @handlers[name][n] = block
    end

    def on_ctcp(name, &block)
      name = name.to_s.downcase
      @ctcps[name] = [] unless @ctcps.include?(name)
      n = @ctcps[name].size
      @ctcps[name][n] = block
    end

    def set_defaults
      on '001' do
        join(@config['channels'])
        if @config.include?('password')
          privmsg :NickServ, "identify #{@config['password']}"
        end
      end

      on :privmsg do
        puts "[#{last.recip}] <#{last.sender.nick}> #{last.text}"
        if last.text.split(' ')[0] == '>>'
          @last.text = "#{@self.nick}: eval #{last.text[3..-1]}"
        end
        Commands.new(self, @config)
      end

      on :ping do
        raw last.full.gsub('PING ','PONG ')
      end

      on '433' do # Nickname in use
        if @config['nicks'].size >= @nick_number
          @nick_number += 1
          puts "NOTICE: Changing nick from #{@self.nick} to #{@config['nicks'][@nick_number]}"
          set_nick @config['nicks'][@nick_number]
        end
      end

      on '311' do
        words = last.text.split(' ')
        if words[0].downcase == @self.nick.downcase
          @self.nick = words[0]
          @self.user = words[1]
          @self.host = words[2]
        end
      end

      on :unknown do
        puts last
      end

      on_ctcp :ping do
        ctcp_reply :ping, last.text
      end

      on_ctcp :action do
        puts "[#{last.recip}] * #{last.sender.nick} #{last.text}"
        case last.text
          when /^kills #{@self.nick}(\s+)?$/
            react 'explodes violently'
          when /^stares oddly at #{@self.nick}$/
            react 'snarls'
        end
      end # on_ctcp :action
    end   # set_defaults

    def set_custom
    end
  end # class Handlers
end   # module Rubino
