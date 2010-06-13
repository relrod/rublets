module Rubino
  class Commands
    def ping(message, *rest)
      [:noprefix, "pong"]
    end

    def hello(message, *rest)
      "hello"
    end

    def reverse_words(message, *rest)
      [:noprefix, rest.reverse]
    end

    def reverse(message, *rest)
      [:noprefix, rest.join(' ').reverse]
    end
  end
end
