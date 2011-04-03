module Users::Follow

  # follow the specified user
  def follow(user)
    return false if user.blank?
    redis   = RedisSocket.new
    user_id = user.is_a?(User) ? user.id : user.to_i
    # add user to my following list
    redis.sadd(following_key, user_id)
    # add me to user's followers list
    redis.sadd(follower_key(user_id), id)
    # send email
    self.class.log("[user:#{id}] #{handle} is following #{user.handle}:#{user.id}")
    Resque.enqueue(UserMailerWorker, :user_following, 'follower_id' => id, 'following_id' => user.id)
    true
  end

  # unfollow the specified user
  def unfollow(user)
    return false if user.blank?
    redis   = RedisSocket.new
    user_id = user.is_a?(User) ? user.id : user.to_i
    # remove user from my following list
    redis.srem(following_key, user_id)
    # remove me from user's followers list
    redis.srem(follower_key(user_id), id)
    self.class.log("[user:#{id}] #{handle} unfollowed #{user.handle}:#{user.id}")
    true
  end

  # unfollow all users the user is currently following
  def unfollow_all
    redis = RedisSocket.new
    redis.smembers(following_key).each do |user_id|
      # remove user from my following list
      redis.srem(following_key, user_id)
      # remove me from user's followers list
      redis.srem(follower_key(user_id), id)
    end
  end

  # return following collection
  def following
    redis = RedisSocket.new
    redis.smembers(following_key)
  end

  def following_ids
    following.map(&:to_i)
  end

  # return number of following
  def following_count
    redis = RedisSocket.new
    redis.scard(following_key)
  end

  # return followers collection
  def followers
    redis = RedisSocket.new
    redis.smembers(follower_key)
  end

  def follower_ids
    followers.map(&:to_i)
  end

  # return number of followers
  def followers_count
    redis = RedisSocket.new
    redis.scard(follower_key)
  end

  def following_key
    "users:#{id}:following"
  end

  def follower_key(user_id=id)
    "users:#{user_id}:followers"
  end
end