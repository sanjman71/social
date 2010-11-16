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
# whenever --update-crontab outlately --load-file config/schedule.outlately.rb
# whenever --write-crontab outlately --load-file config/schedule.outlately.rb

set :environment, :production
set :path, '/usr/apps/outlately/current'
set :output, '/usr/apps/outlately/current/log/cron.log'

every 5.minutes do
  # ping
  command "curl http://outlate.ly/ping > /dev/null"
  # poll recent checkins
  command "curl http://outlate.ly/checkins/poll > /dev/null"
end

every 15.minutes do
  # rebuild sphinx
  command "curl http://outlate.ly/jobs/sphinx?token=5e722026ea70e6e497815ef52f9e73c5ddb8ac26 > /dev/null"
end

every 1.day, :at => '9:00 am' do
  # send todo reminders
  command "curl http://outlate.ly/jobs/todo_reminders?token=5e722026ea70e6e497815ef52f9e73c5ddb8ac26 > /dev/null"
end
