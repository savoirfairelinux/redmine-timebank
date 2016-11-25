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
require 'redmine'

require 'issue_patch'
require 'timebank_helper'
require 'versions_controller_patch'

Redmine::Plugin.register :sfl_timebank do

	name 'SFL TimeBank'
	author 'David Côté-Tremblay'
	description 'Show a table with summation total of spent and estimated hours, scenario points, remaining and projected time for current version.'
	version '0.0.1'
	url 'https://gitlab.savoirfairelinux.com/redmine/SFL-TimeBank'
	author_url 'http://savoirfairelinux.com/'

	settings :default => {
		:tracker_story => nil,
		:tracker_bug => nil,
		:tracker_task => nil
	},:partial => 'sfl_timebank_settings'

end
