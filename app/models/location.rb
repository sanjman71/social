require 'serialized_hash'

class Location < ActiveRecord::Base
  # All addresses must have a country
  validates               :country_id, :presence => true

  belongs_to              :country, :counter_cache => :locations_count
  belongs_to              :state, :counter_cache => :locations_count
  belongs_to              :city, :counter_cache => :locations_count
  belongs_to              :zip, :counter_cache => :locations_count
  belongs_to              :timezone
  has_many                :location_neighborhoods, :dependent => :destroy
  has_many                :neighborhoods, :through => :location_neighborhoods, :after_add => :after_add_neighborhood, :before_remove => :before_remove_neighborhood
  has_many                :email_addresses, :as => :emailable, :dependent => :destroy, :order => "priority asc"
  has_one                 :primary_email_address, :class_name => 'EmailAddress', :as => :emailable, :order => "priority asc"
  accepts_nested_attributes_for :email_addresses, :allow_destroy => true, :reject_if => :all_blank
  has_many                :phone_numbers, :as => :callable, :dependent => :destroy, :order => "priority asc"
  has_one                 :primary_phone_number, :class_name => 'PhoneNumber', :as => :callable, :order => "priority asc"
  accepts_nested_attributes_for :phone_numbers, :allow_destroy => true, :reject_if => :all_blank
  has_many                :location_sources, :dependent => :destroy
  has_one                 :location_source, :class_name => 'LocationSource', :order => 'id desc'
  accepts_nested_attributes_for :location_sources,  :allow_destroy => true, :reject_if => :all_blank

  has_many                :checkins
  has_many                :locationships
  has_many                :users, :through => :locationships

  after_create            :event_location_created

  before_validation(:on => :create) do
    # set default country
    self.country = Country.us if self.country_id.blank?
  end

  acts_as_taggable

  # Note: the after_save_callback is deprecated, but its left here commented out for documentation purposes
  # after_save              :after_save_callback

  serialized_hash         :preferences

  attr_accessor           :matchby, :matchvalue

  # make sure only accessible attributes are written to from forms etc.
  attr_accessible         :name, :country, :country_id, :state, :state_id, :city, :city_id, :zip, :zip_id,
                          :city_state, :street_address, :address, :lat, :lng, :timezone, :timezone_id,
                          :source, :email_addresses_attributes, :phone_numbers_attributes

  # used to generated an seo friendly url parameter
  # acts_as_friendly_param  :place_name

  # scope :no_place,              { :conditions => ["id not in (select distinct location_id from location_places)"] }
  # scope :with_places,           { :joins => :location_places, :conditions => ["location_places.location_id > 0"] }
  scope :with_state,            lambda { |state| { :conditions => ["state_id = ?", state.is_a?(Integer) ? state : state.id] }}
  scope :with_city,             lambda { |city| { :conditions => ["city_id = ?", city.is_a?(Integer) ? city : city.id] }}
  scope :with_neighborhoods,    where("locations.neighborhoods_count > 0")
  scope :no_neighborhoods,      where("locations.neighborhoods_count = 0")
  scope :with_street_address,   where("locations.street_address <> '' AND locations.street_address IS NOT NULL")
  scope :no_street_address,     { :conditions => ["street_address = '' OR street_address IS NULL"] }
  # scope :with_taggings,         { :joins => :companies, :conditions => ["companies.taggings_count > 0"] }
  # scope :no_taggings,           { :joins => :companies, :conditions => ["companies.taggings_count = 0"] }
  scope :with_latlng,           { :conditions => ["lat IS NOT NULL and lng IS NOT NULL"] }
  scope :no_latlng,             { :conditions => ["lat IS NULL and lng IS NULL"] }
  scope :with_phone_numbers,    { :conditions => ["phone_numbers_count > 0"] }
  scope :no_phone_numbers,      { :conditions => ["phone_numbers_count = 0"] }
  scope :min_phone_numbers,     lambda { |x| {:conditions => ["phone_numbers_count >= ?", x] }}
  scope :min_popularity,        lambda { |x| {:conditions => ["popularity >= ?", x] }}
  scope :with_delta,            { :conditions => {:delta => 1} }

  define_index do
    has :id, :as => :location_ids
    indexes name, :as => :name
    indexes street_address, :as => :address
    # location tags
    # indexes tags(:name), :as => :tags
    # has tags(:id), :as => :tag_ids
    # users
    has users(:id), :as => :user_ids
    # locality attributes
    has country_id, :type => :integer, :as => :country_id
    has state_id, :type => :integer, :as => :state_id
    has city_id, :type => :integer, :as => :city_id
    has zip_id, :type => :integer, :as => :zip_id
    has neighborhoods(:id), :as => :neighborhood_ids
    # phone numbers
    indexes phone_numbers(:address), :as => :phone
    # other attributes
    has popularity, :as => :popularity, :type => :integer
    # convert degrees to radians for sphinx
    has 'RADIANS(locations.lat)', :as => :lat,  :type => :float
    has 'RADIANS(locations.lng)', :as => :lng,  :type => :float
    # use delayed job for delta index
    set_property :delta => :delayed
  end

  def self.anywhere
    Location.new do |l|
      l.name = "Anywhere"
      l.send(:id=, 0)
    end
  end

  def self.find_or_create_by_source(hash={})
    case
    when hash[:source]
      location = find_by_source(hash[:source])
    when (hash[:source_type] and hash[:source_id])
      location = find_by_source_id_and_source_type(hash[:source_id], hash[:source_type])
    end

    if location.blank?
      location = Location.create(hash)
    end
    
    location
  end

  # find by location source
  # e.g. "foursquare:1111"
  def self.find_by_source(s)
    stype, sid = s.split(':')
    find_by_source_id_and_source_type(sid, stype)
  rescue
    
  end

  def street_city
    [street_address, city.try(:name)].delete_if(&:blank?).join(', ')
  end

  # return collection of location's country, state, city, zip, neighborhoods
  def localities
    [country, state, city, zip].compact + neighborhoods.compact
  end

  # returns true iff the location has a latitude and longitude 
  def mappable?
    return true if self.lat and self.lng
    false
  end

  def neighborhoodable?
    # can't map to a neighborhood if there is no street address
    return false if street_address.blank?
    # can't map if there's no lat/lng
    mappable?
  end

  def timezone
    if !self.timezone_id.blank?
      Timezone.find_by_id(self.timezone_id)
    elsif !self.city_id.blank?
      # use city's timezone if location timezone is empty
      self.city.timezone
    else
      nil
    end
  end

  def address=(s)
    self.street_address = s
  end

  # set location city, state
  # e.g. "Chicago:IL"
  def city_state=(s)
    @city_name, @state_code = s.split(":")
    @state = State.find_by_code(@state_code)
    @city  = @state.cities.find_by_name(@city_name)
    self.state = @state
    self.city  = @city
  rescue Exception => e
    # invalid city and/or state
  end

  # set location source
  # e.g. "foursquare:1111"
  def source=(s)
    source_type, source_id = s.split(":")
    self.location_sources_attributes = [{:source_type => source_type, :source_id => source_id}]
  rescue Exception => e
    # invalid source
  end

  def refer_to?
    self.refer_to > 0
  end
  
  def geocode_latlng!(options={})
    b = geocode_latlng(options)
    raise Exception, "geocode failed" if b == false
    b
  end
  
  def geocode_latlng(options={})
    force = options.has_key?(:force) ? options[:force] : false
    return true if self.lat and self.lng and !force
    # use street_address, city, state, zip unless any are empty
    geocode_address = [street_address, city ? city.name : nil, state ? state.name : nil, zip ? zip.name : nil].compact.reject(&:blank?).join(" ")
    # multi-geocoder geocode does not throw an exception on failure
    geo = Geokit::Geocoders::MultiGeocoder.geocode(geocode_address)
    return false unless geo.success
    self.lat, self.lng = geo.lat, geo.lng
    self.save
  end

  def hotness
    @hotness ||= 5*locationships.my_checkins.count + 2*locationships.todo_checkins.count
  end

  # called after location is tagged
  def after_tagging
    users.each do |user|
      # add badges for each user linked to this location
      user.delay.async_add_badges
    end
  end

  def event_location_created
    self.class.log("[location:#{self.id}] #{self.name} created")
  end

  def self.log(s, level = :info)
    AppLogger.log(s, nil, level)
  end

  protected
  
  # after_save callback to:
  #  - increment/decrement locality counter caches
  #  x (deprecated) update locality tags (e.g. country, state, city, zip) based on changes to the location object
  # def after_save_callback
  #   changed_set = ["country_id", "state_id", "city_id", "zip_id"]
  #   
  #   self.changes.keys.each do |change|
  #     # filter out unless its a locality
  #     next unless changed_set.include?(change.to_s)
  #     
  #     begin
  #       # get class object
  #       klass_name  = change.split("_").first.titleize
  #       klass       = Module.const_get(klass_name)
  #     rescue
  #       next
  #     end
  #     
  #     old_id, new_id = self.changes[change]
  #     
  #     if old_id
  #       locality = klass.find_by_id(old_id.to_i)
  #       # decrement counter cache
  #       klass.decrement_counter(:locations_count, locality.id)
  #     end
  #     
  #     if new_id
  #       locality = klass.find_by_id(new_id.to_i)
  #       # increment counter cache
  #       klass.increment_counter(:locations_count, locality.id)
  #     end
  #   end
  # end
  
  def after_add_neighborhood(hood)
    return if hood.blank?

    changes = 0

    if self.city_id.blank?
      # set city based on neighborhood city
      self.city = hood.city
      changes += 1
    end

    if self.state_id.blank?
      if self.city_id
        # set state based on location state
        self.state = self.city.state
        changes += 1
      elsif hood.city
        # set state based on neighborhood state
        self.state = hood.city.state
        changes += 1
      end
    end

    self.save if changes > 0
    true
  end

  def before_remove_neighborhood(hood)
    return if hood.blank?
    # decrement counter caches
    Neighborhood.decrement_counter(:locations_count, hood.id)
    Location.decrement_counter(:neighborhoods_count, self.id)
  end
  
end
