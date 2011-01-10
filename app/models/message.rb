class Message
  attr_accessor :to
  attr_accessor :body

  def self.log(s, level = :info)
    AppLogger.log(s, nil, level)
  end

end