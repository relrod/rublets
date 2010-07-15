module Rubino
  class User
    attr_accessor :nick, :user, :host
    def initialize(var)
      if var.is_a?(Hash)
        var.each do |key, value|
          instance_variable_set("@" + key.to_s, value)
        end
      elsif var.is_a?(String)
        if var =~ /^:(.+?)!(.+?)@(\S+) /
          @nick = $1
          @user = $2
          @host = $3
        end
      end
    end

    def data
      {
        :nick => @nick,
        :user => @user,
        :host => @host
      }
    end

    def to_a
      [@nick, @user, @host]
    end

    def to_s
      "#{@nick}!#{@user}@#{@host}"
    end

    def inspect
      to_s
    end
  end # class User
end   # module Rubino
