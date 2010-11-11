# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#

# Learn more: http://github.com/javan/whenever

# Crontab update/write example
# whenever --update-crontab db --load-file config/schedule.db.rb
# whenever --write-crontab db --load-file config/schedule.db.rb

set :environment, :production
set :path, '/usr/apps/outlately/current'
set :output, '/usr/apps/outlately/current/log/backups.log'

every 2.hours do
  rake "db:backup DB=outlately_production BACKUP_DIR=/usr/apps/outlately/shared/backups"
end
