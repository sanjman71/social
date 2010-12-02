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
  
end