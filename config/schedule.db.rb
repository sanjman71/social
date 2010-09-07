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
# whenever --update-crontab db
# whenever --write-crontab db

set :environment, :production
set :path, '/usr/apps/social/current'
set :output, '/usr/apps/social/current/log/backups.log'

every 2.hours do
  rake "db:backup DB=social_production BACKUP_DIR=/usr/apps/social/current/shared"
end
