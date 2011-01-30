class UserMailerWorker
  # resque queue
  @queue = :critical

  def self.perform(method, *args)
    UserMailer.send(method, *args).deliver
  end

end