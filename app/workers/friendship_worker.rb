class FriendshipWorker
  # resque queue
  @queue = :critical

  def self.perform(method, *args)
    self.send(method, *args)
  end

  def self.log(s, level = :info)
    AppLogger.log(s, nil, level)
  end

  def self.update_friend_set(options={})
    user = User.find(options['user_id'])
    user.friend_set_ids = (user.friend_ids + user.inverse_friend_ids).sort.join(',')
    user.save
  end

end
