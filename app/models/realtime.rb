class Realtime

  def self.debug
    puts find_users_out.inspect
  end

  def self.key
    "users:out"
  end

  # mark user as out based on the specified checkin
  def self.mark_user_as_out(user, checkin)
    @redis  = RedisSocket.new
    @score  = checkin.checkin_at.utc.to_i
    @value  = "user:#{user.id}:checkin:#{checkin.id}"
    @redis.zadd(key, @score, @value) rescue -1
  end

  def self.unmark_user_as_out(member)
    @redis  = RedisSocket.new
    @redis.zrem(key, member) rescue -1
  end

  def self.find_users_out
    @redis = RedisSocket.new
    @redis.zrange(key, 0, -1, :with_scores => true)
  end

  def self.add_checkins_sent_while_out(user, checkins)
    @key    = key + ":checkins:sent:#{user.id}"
    @ids    = checkins.collect{ |o| o.respond_to?(:id) ? o.id : o }
    @redis  = RedisSocket.new
    @ids.each do |id|
      @redis.sadd(@key, id)
    end
  end

  def self.find_checkins_sent_while_out(user)
    @key    = key + ":checkins:sent:#{user.id}"
    @redis  = RedisSocket.new
    @redis.smembers(@key)
  end

end