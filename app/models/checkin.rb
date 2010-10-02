class Checkin < ActiveRecord::Base
  # ensure unique checkins, using the facebook, foursquare, whatever source_id
  validates   :user_id,       :presence => true, :uniqueness => {:scope => [:location_id, :source_id, :source_type]}
  validates   :location_id,   :presence => true
  validates   :checkin_at,    :presence => true
  validates   :source_id,     :presence => true
  validates   :source_type,   :presence => true

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
end