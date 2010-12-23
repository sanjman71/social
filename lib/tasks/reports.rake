require 'csv'

namespace :reports do
  
  desc "Build user, checkins, locations report"
  task :basic_user_checkins => :environment do
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
    
    puts data.inspect
    
    path = ENV["FILE"] ? ENV["FILE"] : "basic_user_checkins.#{Time.zone.now.to_s(:datetime_compact)}.csv"
    file = File.open(path, 'w')
    file.write(data)
    file.close
  end
end