
module VersionsControllerPatch

	def self.included(base)
		base.send(:include, InstanceMethods)
		base.class_eval do
			alias_method_chain :show, :timebank
		end
	end

	module InstanceMethods

		def show_with_timebank

			config = Setting.plugin_sfl_timebank

			@version = Version.find(params[:id])
			@project = @version.project

			columns = [:story_points, :estimated_hours, :spent_hours, :remaining_hours, :projected_hours]
			columns.each do |column|
				columns.delete(column) unless SFL_Permissions.is_user_allowed_to?(User.current, :read, column.to_s, project)
			end if Redmine::Plugin.registered_plugins.keys.include? :sfl_backlogs_permissions

			@timebank = {}
			timebank_trackers = [config[:tracker_story], config[:tracker_bug]]
			@timebank[Version] = TimeBankHelper.issues_summations(@version, timebank_trackers, 'category_id', columns)
			@timebank[Project] = TimeBankHelper.issues_summations(@project, timebank_trackers, 'category_id', columns - [:story_points, :estimated_hours])

			@v_issues = {}
			@v_issues[:stories] = TimeBankHelper.issues_summations(@version, [config[:tracker_story], config[:tracker_bug]], 'id', columns)
			@v_issues[:tasks] = TimeBankHelper.issues_summations(@version, [config[:tracker_task]], 'id', columns - [:story_points])

			return show_without_timebank

		end
	end
end

VersionsController.send(:include, VersionsControllerPatch)
