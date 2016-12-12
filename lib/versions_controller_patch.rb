#
#    Copyright (C) 2014 Savoir-faire Linux Inc. (<www.savoirfairelinux.com>).
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as
#    published by the Free Software Foundation, either version 3 of the
#    License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
module VersionsControllerPatch

	def self.included(base)
		base.send(:include, InstanceMethods)
		base.class_eval do
			alias_method_chain :show, :timebank
		end
	end

	module InstanceMethods

		def show_with_timebank

			config = Setting.plugin_redmine_timebank
			if config == '' or config.values.uniq! != nil then
				flash[:error] = "Redmine Time Bank plugin is not properly configured. Go to Admin -> Plugins -> TimeBank"
				return redirect_to @version.project
			end

			story_trackers = config[:story_trackers].map(&:to_i)
			task_trackers = Tracker.all.pluck(:id) - story_trackers

			@version = Version.find(params[:id])
			@project = @version.project

			columns = [:story_points, :estimated_hours, :spent_hours, :remaining_hours]
			if Redmine::Plugin.registered_plugins.keys.include? :sfl_backlogs_permissions then
				columns.delete_if { |column| not SFL_Permissions.is_user_allowed_to?(User.current, :read, column.to_s, @project) }
			end 

			@timebank = {}
			@timebank[Version] = TimeBankHelper.issues_summations(@version, story_trackers, 'category_id', columns)
			@timebank[Project] = TimeBankHelper.issues_summations(@project, story_trackers, 'category_id', columns - [:story_points, :estimated_hours])

			@v_issues = {}
			@v_issues[:stories] = TimeBankHelper.issues_summations(@version, story_trackers, 'id', columns)
			@v_issues[:tasks] = TimeBankHelper.issues_summations(@version, task_trackers, 'id', columns - [:story_points])

			@show_timebanks = columns.count > 0

			return show_without_timebank

		end
	end
end

VersionsController.send(:include, VersionsControllerPatch)
