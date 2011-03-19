class WallMessage < ActiveRecord::Base
  belongs_to  :checkin
  belongs_to  :location
  belongs_to  :sender, :class_name => 'User'
  validates   :message, :presence => true

  # map member_set_ids string to a collection
  def member_set
    (self.member_set_ids || '').split(',').map(&:to_i)
  end

  def send!
    
  end

end