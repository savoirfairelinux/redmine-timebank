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
