class Users < Thor

  desc "show_whos_out", "show users who are out"
  def show_whos_out
    values = Realtime.find_users_out
    puts "#{Time.now}: users out: #{values.size/2} "
    # even values: e.g. "user:1:checkin:5"
    # odd  values: timestamps, e.g. '1296846974'
    values.each_with_index do |value, index|
      next if index.odd?
      match       = value.match(/user:(\d+):checkin:(\d+)/)
      user_id     = match[1]
      user        = User.find_by_id(user_id)
      checkin_id  = match[2]
      checkin     = Checkin.find_by_id(checkin_id)
      timeout     = Time.at(values[index+1].to_i).to_s(:datetime_compact)
      puts "#{Time.now}: [user:#{user.id}] #{user.handle} is marked out at #{checkin.location.try(:name)}:#{timeout}"
    end
  end

  desc "unmark_whos_out", "unmark users who are no longer out"
  def unmark_whos_out
    # find users who are out
    values    = Realtime.find_users_out
    unmarked  = 0
    puts "#{Time.now}: checking users out: #{values.size/2} ..."

    # even values: e.g. "user:1:checkin:5"
    # odd  values: timestamps, e.g. '1296846974'
    values.each_with_index do |value, index|
      next if index.odd?
      match       = value.match(/user:(\d+):checkin:(\d+)/)
      user_id     = match[1]
      user        = User.find_by_id(user_id)
      checkin_id  = match[2]
      checkin     = Checkin.find_by_id(checkin_id)
      # check timestamp (in utc) to see if key has expired
      expires_at  = Time.at(values[index+1].to_i) + Realtime.window_out
      if expires_at.to_i < Time.now.utc.to_i
        puts "#{Time.now}: [user:#{user.id}] #{user.handle} is not out anymore"
        Realtime.unmark_user_as_out(value)
        unmarked += 1
      end
    end

    puts "#{Time.now}: unmarked users: #{unmarked}"
  end

  desc "follow_all_friends", "set members to follow all of their friends"
  def follow_all_friends
    User.member.each do |user|
      user.friend_set.each do |friend_id|
        user.follow(friend_id)
      end
      puts "#{Time.now}:*** user #{user.handle} is following all #{user.friend_set.size} friends"
    end
  end

  desc "unfollow_all", "set members to unfollow all current followers"
  def unfollow_all
    User.member.each do |user|
      user.unfollow_all
      puts "#{Time.now}:*** user #{user.handle} is not following anyone"
    end
  end

  desc "add_location_tags", "tag users with checkin and todo location tags"
  def add_location_tags
    puts "#{Time.now}: adding location tags to users"

    require File.expand_path('config/environment.rb')

    User.all.each do |u|
      begin
        puts "#{Time.now}: [#{u.id}:#{u.handle}] adding tags"
        u.checkin_todo_locations.each do |l|
          u.event_location_tagged(l)
        end
      rescue Exception => e
        puts "#{Time.now}: #{e.message}"
      end
    end

    puts "#{Time.now}: completed"
  end
end