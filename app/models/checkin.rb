class Checkin < ActiveRecord::Base
  validates   :user_id,       :presence => true
  validates   :location_id,   :presence => true
  validates   :checkin_at,    :presence => true
  validates   :source_id,     :presence => true
  validates   :source_type,   :presence => true
  # allow at most 1 checkin per location
  validates_uniqueness_of :user_id, :scope => [:location_id, :source_id, :source_type]
  belongs_to  :location, :counter_cache => :checkins_count
  belongs_to  :user, :counter_cache => :checkins_count

  scope       :foursquare, where(:source_type => 'foursquare')
  scope       :facebook, where(:source_type => 'facebook')
  scope       :recent, :order => 'checkins.checkin_at desc'

  def self.poll_interval
    60.minutes
  end

  def self.min_checkins_for_suggestion
    5
  end
  
  def self.min_low_activity_alert_interval
    12.hours
  end
end