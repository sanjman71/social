class Checkins < Thor

  desc "poll", "poll for recent user checkins"
  def poll
    puts "#{Time.now}: polling user checkins"
    require File.expand_path('config/environment.rb')
    users = Checkin.event_poll_checkins
    users.each do |user|
      puts "#{Time.now}: [user:#{user.id}] #{user.handle} polling checkins"
    end
    puts "#{Time.now}: completed"
  end

  desc "send_todo_reminders", "send checkin todo reminders"
  def send_todo_reminders
    puts "#{Time.now}: checking todo reminders"
    require File.expand_path('config/environment.rb')
    users = User.with_todos
    users.each do |user|
      count = user.send_todo_checkin_reminders
      puts "#{Time.now}: [user:#{user.id}] #{user.handle} sending #{count} todo reminders"
    end
    puts "#{Time.now}: completed"
  end
end