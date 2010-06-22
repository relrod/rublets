require 'yaml'

module Rubino
  class Manager
    def initialize(filename)
      @bots = Hash.new(0)
      @threads = Hash.new(0)
      if File.exist?(filename)
        configure(filename)
      else
        raise "No such file: #{filename}"
      end # if File.exist?(filename)
    end   # def initialize

    def configure(filename)
      @config = YAML.load_file(filename)
      @config['connections'].each do |name,connection| # For each connection
        @config['defaults'].each do |k,v| # Go through the defaults and
          @config['connections'][name][k] ||= v  # Set any previously-unset options
        end
      end   # @config['connections'].each
    end     # def configure

    def run
      @config['connections'].each do |name, connection|
        @bots[name] = Rubino::Bot.new(connection)
        @bots[name].connect
        @threads[name] = Thread.new { @bots[name].run }
      end
    end

    def join_last
      key = @threads.keys[-1]
      @threads[key].join
    end

    def stop_bot(name)
      @bots[name].shutdown
      @threads[name].terminate
      @bots[name] = nil
      @threads[name] = nil
    end

    def shutdown
      @bots.each { |k,v| stop_bot(k) }
    end
  end
end
