class Availability < ActiveRecord::Base
  belongs_to    :user, :touch => true
  # validates     :user_id,   :presence => true # validation doesn't work with nested attributes
  validates     :now, :inclusion => {:in => [true, false]}
  before_save   :check_now_attribute

  before_validation do
    if self.now
      # time fields are required when now is set
      self.start_at = Time.zone.now if self.start_at.blank?
      self.end_at   = Time.zone.now.end_of_day if self.end_at.blank?
    end
  end

  protected

  def check_now_attribute
    if changes[:now]
      if changes[:now][1] == false
        # now is being reset, so clear time fields
        self.start_at = nil
        self.end_at   = nil
      end
      # user.delta automatically changed
      # update user checkins.delta when now is changed
      user.checkins.each do |checkin|
        checkin.update_attribute(:delta, 1)
      end
    end
    if now and Time.zone.now > end_at
      # expired, reset everything
      self.now      = false
      self.start_at = nil
      self.end_at   = nil
    end
  end

end