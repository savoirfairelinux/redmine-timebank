Redmine Time Bank
=================

Savoir-faire Linux
------------------

Show a table with summation total of spent and estimated hours, story points, remaining and projected in version pages.

This plugin is as well compatible with Redmine Backlogs.

![Plugin version time bank screenshot](https://github.com/savoirfairelinux/redmine-timebank/raw/master/screenshots/version.jpg)

Once plugin configured, that chart can be accessed in `Project X -> Roadmap -> Version X -> Bottom of the page`
___


Minimum system requirements
---------------------------

* GNU/Linux operating system
* Redmine ~3.2
* Ruby on Rails >= 4.2
* Ruby >= 1.9.3
* Git >= 2.1.4


Installation procedure
----------------------

We will show you how to install it on Debian family Linux distributions (such as Ubuntu), and Redmine installed with aptitude, but it can works on many other distros with similar procedures.

You may need to do those commands as root, depending on your particular case.

Feel free to replace the variable $REDMINE_PATH to your own Redmine instance path.

```bash
$REDMINE_PATH=/usr/share/redmine/

cd $REDMINE_PATH/plugins/
git clone git@github.com:savoirfairelinux/redmine-timebank.git
mv redmine-timebank redmine_timebank
rake redmine:plugins:migrate RAILS_ENV=production
service apache2 reload  # or depending on which HTTP server you use

```

Configuration procedure
-----------------------

Once installed, to configure the plugin you will first need to go to `Administration -> Plugins -> Redmine Time Bank -> Configuration`

When you're there, you choose the trackers that are considered as stories (ex: Story, Bug, EDS, etc..). Hold CTRL + click the trackers that you want to choose, after this you can save. The plugin should be now ready to use on all projects that have at least one version.

![Plugin settings screenshot](https://github.com/savoirfairelinux/redmine-timebank/raw/master/screenshots/settings.jpg)

Once configurated, you will be able to access time bank tables in versions pages.


Contributing to this plugin
---------------------------

We absolutely appreciate patches, feel free to contribute directly on the GitHub project.

Repositories / Development website / Bug Tracker:
- https://github.com/savoirfairelinux/redmine-timebank

Do not hesitate to join us and post comments, suggestions, questions and general feedback directly on the issues tracker.

**Author :** David Côté-Tremblay <david.cote-tremblay@savoirfairelinux.com>

**Website :** https://www.savoirfairelinux.com/
