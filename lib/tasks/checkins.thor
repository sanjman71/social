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
      if count > 0
        puts "#{Time.now}: [user:#{user.id}] #{user.handle} sending #{count} todo reminders"
      end
    end
    puts "#{Time.now}: completed"
  end

  desc "expire_todos", "expire past todo checkins"
  def expire_todos
    puts "#{Time.now}: expiring todos"
    require File.expand_path('config/environment.rb')
    expired = Locationship.expire_todos
    puts "#{Time.now}: expired #{expired} todos"
  end

  desc "report", "report checkin numbers over days, weeks"
  method_options :emails => nil
  def report
    require File.expand_path('config/environment.rb')
    puts "#{Time.now}: running checkins report ..."
    emails = options[:emails].split(',') rescue []

    puts "#{Time.now}: sending report to: #{emails.any? ? emails.inspect : 'nobody'}"
  end
end
