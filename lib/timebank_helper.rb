# coding: utf-8
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
#
class Hash
	def + x 
		self.merge(x)
	end 
end

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

		template = Hash[*columns.collect { |k| [k, 0.0] }.flatten]
		data = {}

		if group == 'id' then
			selection.each do |grouping|
				data[grouping.to_i] = template.clone unless data.key? grouping
				data[grouping.to_i][:spent_hours] = grouping.total_spent_hours.to_f if columns.include? :spent_hours and project.module_enabled?('time_tracking')
			end
		else
			project.issue_categories.map(&:id).push(nil).each do |grouping|
				data[grouping] = template.clone unless data.key? grouping
				data[grouping][:spent_hours] = selection.where(('issues.'+group) => grouping).map(&:total_spent_hours).inject(:+).to_f
			end if columns.include? :spent_hours and project.module_enabled?('time_tracking')
		end

		selection_with_group.sum(:estimated_hours).each do |grouping, total|
			data[grouping] = template.clone unless data.key? grouping
			data[grouping][:estimated_hours] = total
		end if columns.include? :estimated_hours
		# todo : estimated_hours = if have_decendants then descendants.estimated_hours  else estimated_hours end

		if project.module_enabled?('backlogs') then

			selection_with_group.sum(:story_points).each do |grouping, total|
				data[grouping] = template.clone unless data.key? grouping
				data[grouping][:story_points] = total
			end if columns.include? :story_points

			if columns.include? :remaining_hours then

				selection_with_group.sum(:remaining_hours).each do |grouping, total|
					data[grouping] = template.clone unless data.key? grouping
					data[grouping][:remaining_hours] = total
				end
				selection_with_group.where(in_open_statuses + remaining_hours_is_nil).joins(:status).sum(:story_points).each do |grouping, total|
					data[grouping] = template.clone unless data.key? grouping
					data[grouping][:remaining_hours] += total
				end
				# todo : remaining_hours = if have_decendants then decendants.not_closed else (if remaining_hours then remaining_hours else story_points end) end

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
