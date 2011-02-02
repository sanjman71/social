class CheckinMailerWorker
  # resque queue
  @queue = :critical

  def self.perform(method, *args)
    CheckinMailer.send(method, *args).deliver
  end

end