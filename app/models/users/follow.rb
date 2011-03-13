module Users::Follow

  # follow the specified user
  def follow(user)
    redis = RedisSocket.new
    # add user to my following list
    redis.sadd(following_key, user.id)
    # add me to user's followers list
    redis.sadd(follower_key(user), id)
  end

  # unfollow the specified user
  def unfollow(user)
    redis = RedisSocket.new
    # remove user from my following list
    redis.srem(following_key, user.id)
    # remove me from user's followers list
    redis.srem(follower_key(user), id)
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

  # return number of followers
  def followers_count
    redis = RedisSocket.new
    redis.scard(follower_key)
  end

  def following_key
    "users:#{id}:following"
  end

  def follower_key(user=self)
    "users:#{user.id}:followers"
  end
end