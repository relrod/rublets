require 'socket'

module Rubino
  class Connection < TCPSocket
    def initialize(server)
      @server = server
      super(*server)
    end

    def send(item)
      str = item.to_s
      if str.length > 406
        str = str[0..400] + " (...)"
      end
      self.puts str
    end

    def inspect
      "#<Rubino::Connection #{@server.inspect}>"
    end
  end
end
