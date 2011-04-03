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

every 5.minutes do
  # poll checkins
  command "cd /usr/apps/outlately/current && thor checkins:poll_members >> /usr/apps/outlately/shared/log/checkins.log"
end

# every 10.minutes do
#   # rebuild sphinx
#   rake "ts:index >> /usr/apps/outlately/shared/log/sphinx.log"
# end

every 4.hours do
  # reverse geocode location
  command "cd /usr/apps/outlately/current && thor locations:rgeocode >> /usr/apps/outlately/shared/log/reverse_geocode.log"
end

every 1.hour do
  # backup database
  rake "db:backup DB=outlately_production BACKUP_DIR=/usr/apps/outlately/shared/backups"
end

# times are utc
every 1.day, :at => '1:00 pm' do
  # send planned checkin reminders
  command "cd /usr/apps/outlately/current && thor checkins:send_planned_checkin_reminders >> /usr/apps/outlately/shared/log/checkin_todo_reminders.log"
end

every 1.hour do
  # expire planned checkins
  command "cd /usr/apps/outlately/current && thor checkins:expire_planned_checkins >> /usr/apps/outlately/shared/log/checkin_todo_expired.log"
end

# every 15.minutes do
#   # send realtime checkin messages
#   command "cd /usr/apps/outlately/current && thor checkins:send_realtime >> /usr/apps/outlately/shared/log/checkin_send_realtime.log"
# end

every 15.minutes do
  # check/unmark users out
  command "cd /usr/apps/outlately/current && thor users:unmark_whos_out >> /usr/apps/outlately/shared/log/unmark_whos_out.log"
end

# times are utc
# every 1.day, :at => '1:00 pm' do
#   # send daily checkin emails
#   command "cd /usr/apps/outlately/current && thor checkins:send_daily >> /usr/apps/outlately/shared/log/checkin_send_daily.log"
# end

every 1.day, :at => '11:00 am' do
  # send reports
  command "cd /usr/apps/outlately/current && thor checkins:stats --sendto='sanjay@jarna.com,marchick@gmail.com' >> /usr/apps/outlately/shared/log/checkin_stats.log"
end