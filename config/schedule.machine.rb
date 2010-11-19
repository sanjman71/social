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
# whenever --update-crontab machine --load-file config/schedule.machine.rb
# whenever --write-crontab machine --load-file config/schedule.machine.rb

set :environment, :production
set :path, '/usr/apps/outlately/current'
set :output, '/usr/apps/outlately/current/log/machine.log'

every 2.minutes do
  # machine stats
  command "cd /usr/apps/outlately/current && ./script/machine_stats"
end
