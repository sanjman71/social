class CheckinWorker
  # resque queue
  @queue = :critical

  def self.perform(method, *args)
    self.send(method, *args)
  end

  def self.log(s, level = :info)
    AppLogger.log(s, nil, level)
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
      learn_id    = learn.match(/user:(\d+)/)[1]
      learn_user  = User.find_by_id(learn_id)
      next if learn_user.blank?
      if learn_user.checkins.select(:location_id).collect(&:location_id).include?(checkin.location_id)
        # match - send user an email
        Resque.enqueue(UserMailerWorker, :user_learns, 'user_id' => user.id, 'learn_handle' => learn_user.handle)
        # remove learn
        user.learns_remove(learn_user)
      end
    end
  end

end