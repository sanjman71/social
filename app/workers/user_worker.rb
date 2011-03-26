class UserWorker
  # resque queue
  @queue = :critical

  def self.perform(method, *args)
    self.send(method, *args)
  end

  def self.log(s, level = :info)
    AppLogger.log(s, nil, level)
  end

  def self.member_signup(options={})
    user = User.find(options['user_id'])
    # user auto follows their friends on signup
    user.friend_set.each do |friend_id|
      friend = User.find(friend_id)
      # check if friend is a member
      next unless friend.member?
      user.follow(friend)
    end
  end

end
