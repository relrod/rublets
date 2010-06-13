module Rubino
  class Commands
    attr_accessor :message
    def method_missing(name, *args)
      [name, *args]
    end

    def commands(*args)
      self.class.instance_methods(false).map{|x| x.to_s.gsub('_', ' ') }.join(', ')
    end

    def about(*args)
      "Information about the rubino IRC bot is at http://duckinator.net/rubino"
    end
  end
end
