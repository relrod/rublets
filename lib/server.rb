module Rubino
  class Server
    attr_reader :server, :port, :ssl
    def initialize(server, port=nil)
      @server, @port, @ssl = parse(server, port)
    end

    def to_a
      [@server, @port]
    end

    def inspect
      "#{@server}:#{@port}"
    end

    def parse(server, port=nil)
      ssl = false
      if server.is_a?(Array)
        if server.length != 2
          raise "Invalid use of Server class"
        else
          server, port = server
        end
      elsif server.is_a?(String)
        if server.include?('/') # We got server_name/port
          server, port = server.split('/')
        elsif server.include?(':') # We got server_name:port
          server, port = server.split(':')
        else
          port ||= 6667
        end
      end
      if port.is_a?(String) && port.start_with?('+')
        ssl = true
        port = port[1..-1]
      end

      [server, port.to_i, ssl]
    end

  end # class Server
end   # module Rubino
