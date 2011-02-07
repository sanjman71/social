class CheckinWorker
  # resque queue
  @queue = :critical

  def self.perform(method, *args)
    self.send(method, *args)
  end

  def self.log(s, level = :info)
    AppLogger.log(s, nil, level)
  end

  def self.search_realtime_checkin_matches(options={})
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

  def self.search_similar_checkin_matches(options)
    checkin = Checkin.find_by_id(options['checkin_id'])
    user    = checkin.user
    # find matching checkins
    matches = checkin.match_strategies([:exact, :similar, :nearby], :limit => 3)
    # log data
    log("[user:#{user.id}] #{user.handle} matched checkin:#{checkin.id} with #{matches.size} matches")
    if matches.any?
      # send email
      Resque.enqueue(UserMailerWorker, :user_matching_checkins, 'user_id' => user.id,
                                       'checkin_ids' => [matches.collect(&:id)])
    end
    matches.size
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
        Resque.enqueue(UserMailerWorker, :user_learns, 'user_id' => user.id, 'about_user_id' => about_user.id,
                                         'common_friends' => common_friends)
        # remove learn
        user.learns_remove(about_user)
      end
    end
  end
end