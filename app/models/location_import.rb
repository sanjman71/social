class LocationImport

  # import facebook or foursquare location
  # id: facebook o foursquare id
  # type: 'facebook', 'foursquare'
  # hash: 'name' => 'Zed 451', 'address' => '763 N Clark St.', 'city' => 'Chicago, 'state' => 'Illinois'
  #       'lat' => 41.8964066, 'lng' => -87.6312161
  def self.import_location(id, type, hash)
    # check for existing location using venue id
    @locations = Location.joins(:location_sources) & LocationSource.with_source_id(id).with_source_type(type)
    return @locations.first if @locations.size == 1

    # search for matching locations using venue info
    @locations = LocationFinder.match(hash)
    return @locations.first if @locations.size == 1

    if @locations.size > 1
      # xxx - we found more than 1 matching location
      return nil
    end

    # add new location
    @location = self.add(hash)
    
    if @location
      # add location source
      @location.location_sources.create(:source_id => id.to_s, :source_type => type)
      log(:ok, "[location] added #{@location.name}:#{@location.id}")
    end

    @location
  end

  # add the location to the database
  def self.add(hash)
    @state          = hash['state'].to_s      # e.g. il, illinois
    @city           = hash['city'].to_s       # e.g. chicago
    @address        = hash['address'].to_s    # e.g. 540 N Clark St
    @lat            = hash['lat']
    @lng            = hash['lng']
    @country        = Country.us              # default to 'US'

    if @lat and @lng and @state.blank? and @city.blank? and @address.blank?
      # create location with just a lat, lng
      @location = Location.create(:name => hash['name'], :country => @country, :lat => @lat, :lng => @lng)
      return @location
    end

    # find state, city
    @state          = @state.match(/^[a-zA-Z]{2,2}$/) ? State.find_by_code(@state.upcase) : State.find_by_name(@state)

    if @state.blank?
      return nil
    end

    @city           = @state.cities.find_by_name(@city)

    if @city.blank?
      return nil
    end
    
    # normalize address
    @address        = StreetAddress.normalize(@address) 

    # create location
    options         = Hash[:name => hash['name'], :country => @country, :state => @state, :city => @city, 
                           :street_address => @address, :lat => @lat, :lng => @lng]
    @location       = Location.create(options)
  end

  def self.log(level, s, options={})
    CHECKINS_LOGGER.info("#{Time.now}: [#{level}] #{s}")
  end

end