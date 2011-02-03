class RedisSocket
  
  def self.new
    Redis.new(:db => OUTLATELY_REDIS_DB)
  end

end
