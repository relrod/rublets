module Rubino
  class Message
    attr_accessor :full, :sender, :type, :recip, :text, :ctcp_type
    def initialize(var)
      # @@unprintable contains all non-printable characters
      @@unprintable ||= ["\x00", "\x7F", *"\x02".."\x1F"].join ''
      if var.is_a?(Hash)
        var.each do |key, value|
          instance_variable_set('@' + key.to_s, value)
          @type = @type.to_s
          @ctcp_type = @ctcp_type.to_s
        end
      elsif var.is_a?(String)
        parse(var)
      end
    end

    def to_s
      if @sender
        if @recip
          "#{@sender.nick}!#{@sender.user}@#{@sender.host} #{@type.upcase} #{@recip} :#{@text}"
        else
          "#{@sender.nick}!#{@sender.user}@#{@sender.host} #{@type.upcase} :#{@text}"
        end
      elsif @type
        if @recip
          "#{@type.upcase} #{@recip} :#{text}"
        else
          "#{@type.upcase} :#{@text}"
        end
      else
        @full
      end
    end

    def print
      puts to_s
    end

    def words
      text.split
    end

    def parse(line)
      @full = line.chomp
      @type, @recip, @text, @sender, @ctcp_type = nil

      if line =~ /^:(.+?)!(.+?)@(\S+) (\S+) (\S+) :(.+)$/
        @sender = User.new(
                    :nick => $1,
                    :user => $2,
                    :host => $3
                  )
        @type = $4
        @recip = $5
        @text = $6
      elsif line =~ /^:(\S+) (\S+) (\S+) :?(.*)$/
        @type = $2
        @recip = $3
        @text = $4
      elsif line =~ /^(\S+) :(.*)$/
        @type = $1
        @text = $2
      end

      if !@text.nil?
        @text.gsub!(/\x03\d\d/, '')
        @text.delete!(@@unprintable)

        if @type == "PRIVMSG" && @text[0] == "\x01" && @text[-1] == "\x01" && @text != "\x01"
          words = @text[1..-2].split(' ') 
          @type = "CTCP"
          @ctcp_type = words[0].downcase
          @text = words[1..-1].join(' ')
        end
        @type.downcase!
        @text.delete!("\x01")
      end
    end

    def inspect
      to_s
    end
  end
end
