module IssuePatch
	def self.included(base)
		base.send(:include, InstanceMethods)
	end
	module InstanceMethods
		def to_i
			id
		end
	end
end
Issue.send(:include, IssuePatch)
