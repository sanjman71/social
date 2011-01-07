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
      count = user.send_planned_checkin_reminders
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

  desc "stats", "checkin stats over numbers over days, weeks"
  method_options :sendto => nil
  method_options :filename => nil
  def stats
    require File.expand_path('config/environment.rb')
    require 'csv'
    puts "#{Time.now}: building queries ..."
    sendto    = options[:sendto].split(',') rescue []
    filename  = options[:filename]

    # find total users, member users, non-oath users
    total_users   = User.count
    member_users  = User.member.count
    other_users   = total_users - member_users

    # build daily checkins data
    checkins      = {}
    1.upto(6) do |i|
      checkins_count = Checkin.where(:checkin_at.gt => eval("#{i}.days.ago"), :checkin_at.lt => eval("#{i-1}.days.ago")).count
      checkins[i] = checkins_count
    end

    # build weekly checkin data
    [7, 14, 21, 28].each do |i|
      checkins_count = Checkin.where(:checkin_at.gt => eval("#{i}.days.ago"), :checkin_at.lt => eval("#{i-7}.days.ago")).count
      checkins[i] = checkins_count
    end

    data = CSV.generate(:col_sep => ',') do |csv|
      csv << ['total users', 'members', 'others',
              'checkins 1 day ago', 'checkins 2 days ago', 'checkins 3 days ago', 'checkins 4 days ago',
              'checkins 5 days ago', 'checkins 6 days ago',
              'checkins last week', 'checkins 2 weeks ago', 'checkins 3 weeks ago', 'checkins 4 weeks ago']
      csv << [total_users, member_users, other_users,
              checkins[1], checkins[2], checkins[3], checkins[4], checkins[5], checkins[6],
              checkins[7], checkins[14], checkins[21], checkins[28]
             ]
    end

    # puts data.inspect

    filename ||= "basic_user_checkins.#{Time.zone.now.to_s(:datetime_compact)}.csv"
    file = File.open(filename, 'w')
    file.write(data)
    file.close

    if sendto.any?
      puts "#{Time.now}: sending to: #{sendto.inspect}, file: #{filename}"
      CheckinMailer.checkin_stats(:emails => sendto, :file => filename).deliver
    end
  end
end
