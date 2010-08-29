class Checkin < ActiveRecord::Base
  validates   :user_id, :presence => true
  validates   :location_id, :presence => true
  validates   :checkin_at, :presence => true
  validates   :source_id, :presence => true
  validates   :source_type, :presence => true
  # allow at most 1 checkin per location
  validates_uniqueness_of :user_id, :scope => [:location_id, :source_id, :source_type]
  belongs_to  :location
  belongs_to  :user
end