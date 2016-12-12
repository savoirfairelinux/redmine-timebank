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

		selection = Issue.where(in_scope + in_trackers)
		selection_with_group = selection.group('COALESCE(issues.'+group+', NULL)')
		with_children = 'issues.rgt != issues.lft + 1'

		template = Hash[*columns.collect { |k| [k, 0.0] }.flatten]
		data = {}

		if group == 'id' then
			selection.each do |grouping|
				data[grouping.to_i] = template.clone unless data.key? grouping.to_i
				data[grouping.to_i][:spent_hours] = grouping.total_spent_hours.to_f
			end
		else
			project.issue_categories.map(&:id).push(nil).each do |grouping|
				data[grouping] = template.clone unless data.key? grouping
				data[grouping][:spent_hours] = selection.where(('issues.'+group) => grouping).map(&:total_spent_hours).inject(:+).to_f
			end
		end if columns.include? :spent_hours and project.module_enabled?('time_tracking')

		if group == 'id' then
			selection.each do |grouping|
				data[grouping.to_i] = template.clone unless data.key? grouping.to_i
				data[grouping.to_i][:estimated_hours] = if grouping.descendants.empty? then
					grouping.estimated_hours
				else
					grouping.descendants.flatten.collect{|x| x[:estimated_hours]}.compact.sum
				end.to_f
			end
		else
			project.issue_categories.map(&:id).push(nil).each do |grouping|
				data[grouping] = template.clone unless data.key? grouping
				in_group_selection = selection.where({('issues.'+group) => grouping})
				data[grouping][:estimated_hours] = in_group_selection.where(with_children).map(&:descendants).flatten.collect{|x| x[:estimated_hours]}.compact.sum
				data[grouping][:estimated_hours] += in_group_selection.where.not(with_children).collect{|x| x[:estimated_hours]}.compact.sum
			end
		end if columns.include? :estimated_hours

		if project.module_enabled?('backlogs') then

			selection_with_group.sum(:story_points).each do |grouping, total|
				data[grouping] = template.clone unless data.key? grouping
				data[grouping][:story_points] = total
			end if columns.include? :story_points

			if columns.include? :remaining_hours then

				open_statuses_ids = IssueStatus.where(:is_closed => false).pluck(:id)
				project.issue_categories.map(&:id).push(nil).each do |grouping|
					data[grouping] = template.clone unless data.key? grouping
					in_group_selection = selection.where({('issues.'+group) => grouping})
					data[grouping][:remaining_hours] = in_group_selection.where(with_children).map(&:descendants).flatten.collect{|x| x[:remaining_hours]}.compact.sum
					data[grouping][:remaining_hours] += in_group_selection.joins(:status).where(in_open_statuses).where.not(with_children).collect{
						|x| x[:remaining_hours] || x[:story_points]
					}.compact.sum
				end

				data.each do |grouping, _columns|
					data[grouping] = template.clone unless data.key? grouping
					data[grouping][:projected_hours] = _columns[:spent_hours] + _columns[:remaining_hours]
				end if columns.include? :spent_hours and project.module_enabled?('time_tracking')

			end
		end

		return {
			:table => data,
			:totals => self.do_totalizations(data)
		}

	end

end

class Hash
	def + x 
		self.merge(x)
	end 
end
