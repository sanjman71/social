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
# whenever --update-crontab social
# whenever --write-crontab social

set :environment, :production
set :path, '/usr/apps/social/current'
set :output, '/usr/apps/social/current/log/cron.log'

every 5.minutes do
  # poll recent checkins
  command "curl http://www.socialintrigue.com/checkins/poll > /dev/null"
end
