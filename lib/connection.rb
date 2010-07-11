require 'socket'

module Rubino
  class Connection < TCPSocket
    def initialize(server)
      @server = server
      super(*server)
    end

    def send(item)
      self.puts item.to_s
    end

    def inspect
      "#<Rubino::Connection #{@server.inspect}>"
    end
  end
end
