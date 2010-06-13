module Rubino
  class Commands
    def a(message, *rest)
      char = 'b'
      char = rest[-1][-1,1].succ if rest.size > 0
      (char..'z').to_a.join(' ')
    end

    def do_you_live?(message, *rest)
      [:noprefix, "No, I died."]
    end

    def ping(message, *rest)
      [:noprefix, "pong"]
    end

    def hello(message, *rest)
      "hello"
    end

    def reverse(message, *rest)
      [:noprefix, rest.join(' ').reverse]
    end

    def reverse_words(message, *rest)
      [:noprefix, rest.reverse]
    end

    def commands(message, *rest)
      self.class.instance_methods(false).map{|x| x.to_s.gsub('_', ' ') }.join(', ')
    end
  end
end
