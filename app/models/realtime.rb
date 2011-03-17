class Realtime

  def self.debug
    puts find_users_out.inspect
  end

  # the time window after a checkin the user is considered out
  def self.window_out
    2.hours
  end

  def self.key
    "users:out"
  end

  # mark user as out because of the specified checkin
  def self.mark_user_as_out(user, checkin)
    @redis  = RedisSocket.new
    @score  = checkin.checkin_at.utc.to_i
    @value  = "user:#{user.id}:checkin:#{checkin.id}"
    @redis.zadd(key, @score, @value) rescue -1
  end

  # unmark user as out
  def self.unmark_user_as_out(member)
    @redis  = RedisSocket.new
    @redis.zrem(key, member) rescue -1
  end

  # find list of users out
  def self.find_users_out(options={})
    @redis = RedisSocket.new
    scores = options.has_key?(:scores) ? options[:scores] : true
    scores = false if options[:map_ids]
    data   = @redis.zrange(key, 0, -1, :with_scores => scores)
    if options[:map_ids]
      data = data.inject(ActiveSupport::OrderedHash.new) do |hash, value|
        # each value looks like "user:id:checkin:id"
        match       = value.match(/user:(\d+):checkin:(\d+)/)
        user_id     = match[1].to_i
        checkin_id  = match[2].to_i
        hash[user_id] ||= []
        hash[user_id].push(checkin_id)
        hash
      end
    end
    data
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