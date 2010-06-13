module Rubino
  class User
    attr_accessor :nick, :user, :host
    def initialize(var)
      if var.is_a?(Hash)
        var.each do |key, value|
          instance_variable_set("@" + key, value)
        end
      elsif var.is_a?(String)
        if var =~ /^:(.+?)!(.+?)@(\S+) /
          @nick = $1
          @user = $2
          @host = $3
        end
      end
    end

    def inspect
      {
        :nick => @nick,
        :user => @user,
        :host => @host
      }
    end
  end # class User
end   # module Rubino
