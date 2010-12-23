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

every :reboot do
  command "monit" # might require path to be set in crontab
end

every 7.minutes do
  # poll checkins
  command "cd /usr/apps/outlately/current && thor checkins:poll >> /usr/apps/outlately/shared/log/checkins.log"
end

every 30.minutes do
  # rebuild sphinx
  rake "ts:index >> /usr/apps/outlately/shared/log/sphinx.log"
end

every 4.hours do
  # reverse geocode location
  command "cd /usr/apps/outlately/current && thor locations:rgeocode >> /usr/apps/outlately/shared/log/reverse_geocode.log"
end

every 1.hour do
  # backup database
  rake "db:backup DB=outlately_production BACKUP_DIR=/usr/apps/outlately/shared/backups"
end

every 1.day, :at => '9:00 am' do
  # send todo reminders
  command "cd /usr/apps/outlately/current && thor checkins:send_todo_reminders >> /usr/apps/outlately/shared/log/checkin_todo_reminders.log"
end

every 1.hour do
  # expire todos
  command "cd /usr/apps/outlately/current && thor checkins:expire_todos >> /usr/apps/outlately/shared/log/checkin_todo_expired.log"
end
