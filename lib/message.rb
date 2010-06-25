module Rubino
  class Message
    attr_accessor :full, :sender, :type, :recip, :text
    def initialize(var)
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
      @type, @recip, @text, @sender = nil
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
      @text.chomp! unless @text.nil?
    end

    def inspect
      @full || generate
    end
  end
end
