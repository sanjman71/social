class AppLogger
  
  def self.logger
    @@logger ||= Logger.new("log/outlately.#{Rails.env}.log")
  end
  
  # topic - e.g. :checkin, :location, :user
  # level - e.g. :debug, :info, :error
  def self.log(message, topic = nil, level = :info)
    if level == :error
      message = "[error] #{message}"
    end
    logger.send(level.to_s, "#{Time.now.to_s(:datetime_compact)} #{message}")
  end

end