class WallMessage < ActiveRecord::Base
  belongs_to  :wall, :counter_cache => :messages_count, :dependent => :destroy
  belongs_to  :sender, :class_name => 'User'
  validates   :message, :presence => true

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

end