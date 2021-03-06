class Neighborhood < ActiveRecord::Base
  validates_presence_of       :name, :city_id
  validates_uniqueness_of     :name, :scope => :city_id
  belongs_to                  :city, :counter_cache => :neighborhoods_count
  has_many                    :location_neighborhoods
  has_many                    :locations, :through => :location_neighborhoods
  has_many                    :geo_tag_counts, :as => :geo
  has_many                    :tags, :through => :geo_tag_counts

  # include GeoTagCountModule

  include NameParam

  # find neighborhoods named with characters such as [', -]
  scope :find_like,           lambda { |s| {:conditions => ["name LIKE ?", s]} }

  scope :with_locations,      { :conditions => ["locations_count > 0"] }
  scope :with_events,         { :conditions => ["events_count > 0"] }
  scope :with_tags,           { :conditions => ["tags_count > 0"] }
  scope :no_tags,             { :conditions => ["tags_count = 0"] }

  # order neighborhoods by locations, events
  scope :order_by_density,    { :order => "locations_count DESC" }
  scope :order_by_events,     { :order => "events_count DESC" }
  

  # max distance where locations are considered to be in the same neighborhood
  def self.within_neighborhood_distance_meters
    100.0
  end

  def self.within_neighborhood_distance_miles
    Math.meters_to_miles(self.within_neighborhood_distance_meters)
  end
  
  def to_param
    self.name.to_url_param
  end

end
