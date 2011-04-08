class WallMessage < ActiveRecord::Base
  belongs_to    :wall, :counter_cache => :messages_count, :dependent => :destroy
  belongs_to    :sender, :class_name => 'User'
  validates     :message, :presence => true

  after_create  :event_wall_message_created
  after_save    :event_wall_message_saved

  # custom validator
  validate do |object|
    object.validate_sender
  end

  def validate_sender
    # sender must be a wall member
    if !wall.member_set.include?(sender_id)
      errors.add(:sender, "invalid sender")
    end
  end

  def send!(options={})
    push = (options[:push] == true) || (options[:push] == 1)
  end

  def event_wall_message_created
    self.class.log("[user:#{sender.id}] #{sender.handle} wrote on chalkboard:#{wall.id}:#{wall.location.try(:name)} message:#{id}:#{message}")
    Resque.enqueue(ChalkboardWorker, :message_created, "wall_message_id" => id)
  end

  def event_wall_message_saved
    wall.update_attribute(:updated_at, updated_at)
  end

  def self.log(s, level = :info)
    AppLogger.log(s, nil, level)
  end

end