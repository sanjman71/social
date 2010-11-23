class Availability < ActiveRecord::Base
  belongs_to    :user
  # validates     :user_id,   :presence => true # validation doesn't work with nested attributes
  # validates   :start_at, :presence => true
  # validates   :end_at,   :presence => true
  validates     :now, :presence => true, :inclusion => {:in => [true, false]}
  before_save   :check_now_attribute

  before_validation do
    if self.now
      # start_at and end_at are required if now is set
      self.start_at = Time.zone.now if self.start_at.blank?
      self.end_at   = Time.zone.now + self.class.default_now_hours if self.end_at.blank?
    end
  end

  def self.default_now_hours
    4.hours
  end

  protected

  def check_now_attribute
    if changes[:now]
      if changes[:now][1] == false
        # now is being reset, so clear start_at and end_at
        self.start_at = nil
        self.end_at   = nil
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