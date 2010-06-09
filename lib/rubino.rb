module Rubino
	class Bot
		def initialize(opts)
			opts.each do |key, value|
				instance_variable_set("@" + key, value)
			end	
		end
	end	
end
