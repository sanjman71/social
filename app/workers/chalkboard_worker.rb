class ChalkboardWorker
  # resque queue
  @queue = :critical

  def self.log(s, level = :info)
    AppLogger.log(s, nil, level)
  end

  def self.perform(method, *args)
    self.send(method, *args)
  end

  def self.message_created(options)
    @wall_message = WallMessage.find(options['wall_message_id'])
    @wall         = @wall_message.wall
    @sender       = @wall_message.sender

    @wall_message.wall.members.each do |user|
      # exclude sender and check preferences
      next if user == @sender
      if user.preferences_chalkboard_message_email.to_i == 1
        log("[chalkboard:#{@wall.id}] #{@wall.location.try(:name)} message:#{@wall_message.id} sending to user:#{user.id}:#{user.handle}")
        Resque.enqueue(UserMailerWorker, :user_chalkboard_message, 'user_id' => user.id,
                       'wall_message_id' => @wall_message.id)
      end
    end
  end

end
