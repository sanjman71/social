class CheckinWorker
  # resque queue
  @queue = :critical

  def self.perform(method, *args)
    self.send(method, *args)
  end

  def self.log(s, level = :info)
    AppLogger.log(s, nil, level)
  end

  def self.send_realtime_friend_checkin(options={})
    checkin = Checkin.find(options['checkin_id'])
    user    = checkin.user

    # find member followers
    followers = User.find(user.followers)
    followers.each do |follower|
      # should always be members, but check anyway
      next unless follower.member?
      # check follower's preferences
      if follower.preferences_follow_all_checkins_email.to_i == 1
        log("[user:#{user.id}] #{user.handle} sending checkin email to follower:#{follower.id}:#{follower.handle}")
      elsif follower.preferences_follow_nearby_checkins_email.to_i == 1
        # check distance between folower and checkin
        # use follower's last checkin within 24 hours, default to follower's city
        geo       = follower.last_checkin_after(24.hours.ago).try(:location) || follower.city
        distance  = Distance.checkin_distance(geo, checkin)
        if distance <= 20.0
          log("[user:#{user.id}] #{user.handle} sending checkin email to follower:#{follower.id}:#{follower.handle}, distance #{distance} lt 20")
        else
          log("[user:#{user.id}] #{user.handle} discarding checkin email to follower:#{follower.id}:#{follower.handle}, distance #{distance} gt 20")
          return
        end
      end
      # send email
      Resque.enqueue(UserMailerWorker, :user_friend_realtime_checkin,
                     'user_id' => follower.id, 'checkin_id' => checkin.id)
    end
  end

  def self.search_realtime_checkin_matches(options={})
    # check feature
    return unless enabled(:realtime_checkin_matches)

    # find users who are out
    values = Realtime.find_users_out

    # even values: e.g. "user:1:checkin:5"
    # odd  values: timestamps, e.g. '1296846974'
    values.each_with_index do |value, index|
      next if index.odd?
      match       = value.match(/user:(\d+):checkin:(\d+)/)
      user_id     = match[1]
      user        = User.find_by_id(user_id)
      checkin_id  = match[2]
      checkin     = Checkin.find_by_id(checkin_id)
      # skip non-members
      next unless user.member?
      # check timestamp (in utc) to see if key has expired
      expires_at  = Time.at(values[index+1].to_i) + 1.hour
      if expires_at.to_i < Time.now.utc.to_i
        log("[user:#{user.id}] #{user.handle} is not out anymore")
        Realtime.unmark_user_as_out(value)
      end
      # find nearby checkins within +/- 1 hour, exclude checkins already sent
      without_ids = Realtime.find_checkins_sent_while_out(user).collect(&:to_i)
      timerange   = Range.new(checkin.checkin_at.utc-1.hour, checkin.checkin_at.utc+1.hour)
      matches     = checkin.match_strategies([:nearby], :with_timestamp_at => timerange,
                                             :without_checkin_ids => without_ids, :limit => 3)
      log("[user:#{user.id}] #{user.handle} is out, found #{matches.size} realtime checkin matches")
      if matches.any?
        # track checkins sent while user is out
        Realtime.add_checkins_sent_while_out(user, matches)
        # send email
        Resque.enqueue(UserMailerWorker, :user_nearby_realtime_checkins, 'user_id' => user.id,
                                         'checkin_id' => checkin.id, 'checkin_ids' => [matches.collect(&:id)])
      end
    end
  end

  def self.search_daily_checkin_matches(options={})
    # check feature
    return unless enabled(:daily_checkin_matches)

    tstart              = (Time.zone.now-1.day).beginning_of_day
    tend                = tstart.end_of_day
    checkins_per_email  = 3

    # find members who checked in between [tstart, tend]
    User.member.each do |user|
      # user.send_daily_checkin_emails(:tstart => tstart, :tend => tend)
      user_checkins = user.checkins.where(:checkin_at.gte => tstart, :checkin_at.lte => tend)
      if user_checkins.any?
        matches = user_checkins.inject([]) do |array, checkin|
          # find matching checkins
          limit   = checkins_per_email - array.size
          matches = limit > 0 ? checkin.match_strategies([:exact, :similar], :limit => limit) : []
          # log data
          log("[user:#{user.id}] #{user.handle} daily checkin match:#{checkin.id} with #{matches.size} matches")
          array  += matches
        end
        if matches.any?
          # send email
          Resque.enqueue(UserMailerWorker, :user_daily_checkins,
                         'user_id' => user.id, 'my_checkin_ids' => user_checkins.collect(&:id),
                         'checkin_ids' => matches.collect(&:id))
        end
      end
    end
  end

  def self.search_learn_matches(options)
    checkin = Checkin.find_by_id(options['checkin_id'])
    user    = checkin.user
    learns  = user.learns_get
    return if learns.empty?

    learns.each do |learn|
      about_id    = learn.match(/user:(\d+)/)[1]
      about_user  = User.find_by_id(about_id)
      next if about_user.blank?
      if about_user.checkins.select(:location_id).collect(&:location_id).include?(checkin.location_id)
        # match - send user an email with common friends
        common_friends = User.common_friends(user, about_user).size
        Resque.enqueue(UserMailerWorker, :user_learn_more, 'user_id' => user.id, 'about_user_id' => about_user.id,
                                         'common_friends' => common_friends)
        # remove learn
        user.learns_remove(about_user)
      end
    end
  end
end