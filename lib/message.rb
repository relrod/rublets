module Rubino
  class Message
    attr_accessor :full, :sender, :type, :recip, :text, :ctcp_type
    def initialize(irc, var)
      @irc = irc
      if var.is_a?(Hash)
        var.each do |key, value|
          instance_variable_set("@" + key, value)
        end
      elsif var.is_a?(String)
        parse(var)
      end
    end

    def generate
      "#{@sender.nick}!#{@sender.user}@#{@sender.host} #{type.upcase} :#{text}"
    end

    def words
      text.split
    end

    def parse(line)
      @full = line
      @type, @recip, @text, @sender, @ctcp_type = nil
      if line =~ /^:(.+)!(.+)@(\S+) (\S+) (\S+) :(.+)$/
        @sender = User.new(
                    :nick => $1,
                    :user => $2,
                    :host => $3
                  )
        @type = $4
        @recip = $5
        @text = $6
      elsif line =~ /^:(\S+) (\S+) (\S+) :?(.+)$/
        @type = $2
        @recip = $3
        @text = $4
      elsif line =~ /^(\S+) :(.+)$/
        @type = $1
        @text = $2
      end
      if !@text.nil?
        @text.gsub!(/\x03\d\d/, '')
        # non_printable contains all non-printable characters
        non_printable = ["\x00", *"\x02".."\x1F", "\x7F"]
        non_printable.map do |c|
          @text.delete!(c) # Delete all instances of c in @text
        end

        if @type == "PRIVMSG" && @text[0] == "\x01" && @text[-1] == "\x01"
          words = @text[1..-2].split(' ') 
          @type = "CTCP"
          @ctcp_type = words[0]
          @text = words[1..-1].join(' ')
        end
        @text.delete!("\x01")
      end
      if @recip == @irc.nick && !@sender.nil?
        @recip = @sender.nick
      end
    end

    def inspect
      @full || generate
    end
  end
end
