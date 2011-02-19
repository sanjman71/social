class BadgeWorker
  # resque queue
  @queue = :critical

  def self.perform(method, *args)
    self.send(method, *args)
  end

  def self.log(s, level = :info)
    AppLogger.log(s, nil, level)
  end

  def self.async_badge_discovery(options={})
    if options['user_id']
      # user specific badge discovery
      users = Array(User.find_by_id(options['user_id']))
    else
      # all members badge discovery
      users = User.member
    end
    # add any missing badges to users collection
    users.each do |user|
      user.async_add_badges
    end
  end

end