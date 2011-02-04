class RedisSocket
  
  def self.new
    Redis.new(:db => OUTLATELY_REDIS_DB)
  end

  def self.reset!
    redis = RedisSocket.new
    redis.flushdb
  end

end
