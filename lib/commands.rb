module Rubino
  class Commands
    attr_accessor :message
    def commands(*args)
      self.class.instance_methods(false).map do |x|
        # We don't want to mention the .message and .message= methods
        if x.to_s.gsub('=','') != 'message'
          x.to_s.gsub('_', ' ')
        end
      end.delete_if(&:nil?).join(', ')
    end
    
    def about(*args)
      "Information about the rubino IRC bot is at http://duckinator.net/rubino"
    end
  end
end
