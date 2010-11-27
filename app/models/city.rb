class City < ActiveRecord::Base
  validates                   :name, :presence => true, :uniqueness => {:scope => :state_id}
  validates                   :country_id, :presence => true
  belongs_to                  :state, :counter_cache => true
  belongs_to                  :country
  belongs_to                  :timezone
  has_many                    :neighborhoods
  has_many                    :locations
  has_many                    :city_zips
  has_many                    :zips, :through => :city_zips
  has_many                    :geo_tag_counts, :as => :geo
  has_many                    :tags, :through => :geo_tag_counts

  before_validation(:on => :create) do
    self.country = state.try(:country) if self.country_id.blank?
  end

  # acts_as_mappable
  include Geokit::Mappable

  # include GeoTagCountModule
  include NameParam

  attr_accessible               :name, :state, :state_id, :country, :country_id, :lat, :lng

  scope :exclude,               lambda { |city| {:conditions => ["id <> ?", city.is_a?(Integer) ? city : city.id] } }
  scope :within_state,          lambda { |state| {:conditions => ["state_id = ?", state.is_a?(Integer) ? state : state.id] } }

  scope :with_locations,        { :conditions => ["locations_count > 0"] }
  scope :with_neighborhoods,    { :conditions => ["neighborhoods_count > 0"] }
  scope :with_events,           { :conditions => ["events_count > 0"] }
  scope :with_tags,             { :conditions => ["tags_count > 0"] }
  scope :no_tags,               { :conditions => ["tags_count = 0"] }

  # find cities with/without lat/lng
  scope :with_latlng,           { :conditions => ["lat IS NOT NULL AND lng IS NOT NULL"] }
  scope :no_latlng,             { :conditions => ["lat IS NULL AND lng IS NULL"] }

  # find cities with/without timezones
  scope :with_timezones,        { :conditions => ["timezone_id IS NOT NULL"] }
  scope :no_timezones,          { :conditions => ["timezone_id IS NULL"] }

  scope :min_density,           lambda { |density| { :conditions => ["locations_count >= ?", density] }}

  # order cities by locations, events
  scope :order_by_density,      { :order => "locations_count DESC" }
  scope :order_by_events,       { :order => "events_count DESC" }

  # order cities by name
  scope :order_by_name,         { :order => "name ASC" }
  scope :order_by_state_name,   { :order => "state_id ASC, name ASC" }

  # the special anywhere object
  def self.anywhere(state=nil)
    City.new do |o|
      o.name      = "Anywhere"
      o.state_id  = state.id if state
      o.send(:id=, 0)
    end
  end

  def self.popular_density
    25000
  end

  def anywhere?
    self.id == 0
  end
  
  def to_param
    self.name.to_url_param
  end
  
  def city_state
    [name, state.present? ? state.try(:code) : country.try(:code)].delete_if(&:blank?).join(", ")
  end

  def geocode_latlng(options={})
    force = options.has_key?(:force) ? options[:force] : false
    return true if self.lat and self.lng and !force
    # multi-geocoder geocode does not throw an exception on failure
    geo = Geokit::Geocoders::MultiGeocoder.geocode("#{name}, #{state.name}")
    return false unless geo.success
    self.lat, self.lng = geo.lat, geo.lng
    self.save
  end

  def has_locations?
    self.locations_count > 0
  end
  
  # convert city to a string of attributes separated by '|'
  def to_csv
    [self.name, self.state.code, self.lat, self.lng].join("|")
  end

  # find city name or create if it doesn't exist
  def self.find_by_name_or_geocode(s)
    city = self.find_by_name(s)
    return city if city
    
    # multi-geocoder geocode does not throw an exception on failure
    geo = Geokit::Geocoders::MultiGeocoder.geocode("#{s}")
    return nil unless geo.success
    
    state = State.find_by_code(geo.state) 
    city  = self.create(:name => geo.city || geo.district, :lat => geo.lat, :lng => geo.lng, :state => state)
  end

  # set city zips using sphinx facets 
  def set_zips(limit=nil)
    limit       ||= ::Search.max_matches
    facets      = Location.facets(:with => ::Search.attributes(self), :facets => ["zipcode_id"], :limit => limit)
    search_zips = ::Search.load_from_facets(facets, Zipcode)

    # build list of zips to add and delete

    cur_zips  = self.zips
    add_zips  = search_zips - cur_zips
    del_zips  = cur_zips - search_zips
    added     = 0
    deleted   = 0

    add_zips.each do |zip|
      self.city_zips.create(:zip => zip)
      added += 1
    end

    del_zips.each do |zip|
      o = self.city_zips.find_by_zip_id(zip.id)
      self.city_zips.delete(o)
      deleted += 1
    end

    [added, deleted]
  end
  
  # import cities
  def self.import(options={})
    imported  = 0
    file      = options[:file] ? options[:file] : "#{Rails.root}/data/cities.txt"
    
    CSV.foreach(file, :col_sep => '|') do |row|
      city_name, state_code, lat, lng = row

      # validate state
      state = State.find_by_code(state_code)
      next if state.blank?

      # skip if city exists
      next if state.cities.find_by_name(city_name)

      # create city
      city = state.cities.create(:name => city_name, :lat => lat, :lng => lng)
      imported += 1
    end
    
    imported
  end
  
end
