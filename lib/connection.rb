require 'socket'

module Rubino
  class Connection < TCPSocket
    def initialize(server)
      super(*server.inspect)
    end
  end
end
