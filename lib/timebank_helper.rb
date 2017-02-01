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
module TimeBankHelper

	def self.do_totalizations(summations)
		data = {}
		summations.each do |grouping, columns|
			columns.each do |column, value|
				data[column] = 0 unless data.key? column
				data[column] += value.to_f
			end
		end
		return data
	end

	def self.chainsum(flattened, symb)
		flattened.collect{|x| x[symb]}.compact.sum
	end

	def self.issues_summations(scope, trackers, group, columns)

		project = nil
		in_scope = nil
		case scope
			when Version
				in_scope = {:fixed_version => scope}
				project = scope.project
			when Project
				in_scope = {:project => scope}
				project = scope
			else
				raise "The entered scope is not supported."
		end

		in_trackers = {:tracker => trackers}
		in_open_statuses = {:issue_statuses => {:is_closed => false}}
		remaining_hours_is_nil = {:remaining_hours => nil}

		selection = Issue.where(in_scope, in_trackers)
		selection_with_group = selection.group('COALESCE(issues.'+group+', NULL)')
		with_children = 'issues.rgt != issues.lft + 1'

		template = Hash[*columns.collect { |k| [k, 0.0] }.flatten]
		data = {}

		if project.module_enabled?('backlogs') and columns.include? :remaining_hours then
			open_statuses_ids = IssueStatus.where(:is_closed => false).pluck(:id)
		end

		gkey = 'issues.'+group
		single = group == 'id'

		if single then selection else
			project.issue_categories.map(&:id).push(nil)
		end.each do |grouping|

			in_group_selection = unless single then selection.where({gkey => grouping}) end
			chunk = template.clone
			
			chunk[:spent_hours] = if single then
				grouping.total_spent_hours
			else
				selection.where(gkey => grouping).map(&:total_spent_hours).inject(:+)
			end.to_f if columns.include? :spent_hours and project.module_enabled?('time_tracking')

			chunk[:estimated_hours] = if single then
				if grouping.descendants.empty? then grouping.estimated_hours else
					self.chainsum(grouping.descendants.flatten, :estimated_hours)
				end
			else
				self.chainsum(in_group_selection.where(with_children).map(&:descendants).flatten, :estimated_hours) +
					self.chainsum(in_group_selection.where.not(with_children), :estimated_hours)
			end.to_f if columns.include? :estimated_hours

			if project.module_enabled?('backlogs') and columns.include? :remaining_hours then

				chunk[:remaining_hours] = if single then 
					if grouping.descendants.empty? then
						grouping.status.is_closed ? 0 : grouping.estimated_hours
					else
						grouping.descendants.flatten.collect{
							|x| (open_statuses_ids.include? x[:status_id]) ? x[:remaining_hours] : 0
						}.compact.sum
					end
				else
					self.chainsum(in_group_selection.where(with_children).map(&:descendants).flatten, :remaining_hours) +
						in_group_selection.joins(:status).where(in_open_statuses).where.not(with_children).collect{
							|x| x[:remaining_hours] || x[:story_points]
						}.compact.sum
				end.to_f

				if columns.include? :spent_hours and project.module_enabled?('time_tracking')
					chunk[:projected_hours] = chunk[:spent_hours] + chunk[:remaining_hours]
				end 
			end

			data[if single then grouping.to_i else grouping end] = chunk
		end

		selection_with_group.sum(:story_points).each do |grouping, total|
			data[grouping][:story_points] = total
		end if project.module_enabled?('backlogs') and columns.include? :story_points

		return {
			:table => data,
			:totals => self.do_totalizations(data)
		}
	end
end
