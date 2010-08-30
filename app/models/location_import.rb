class LocationImport

  # import a foursquare venue location hash
  # e.g. "venue"=>{"id"=>4172889, "name"=>"Zed 451", "address"=>"763 N. Clark St.", "city"=>"Chicago", "state"=>"Illinois",
  #                "geolat"=>41.8964066, "geolong"=>-87.6312161}
  def self.import_foursquare_venue(hash)
    # normalize venue hash
    @hash = Hash['name' => hash['name'], 'address' => hash['address'], 'city' => hash['city'],
                 'state' => hash['state'], 'lat' => hash['geolat'], 'lng' => hash['geolong']]
    import_venue(hash['id'].to_s, Source.foursquare, @hash)
  end

  # import a facebook place location hash
  # e.g. "place"=>{"id"=>"117669674925118", "name"=>"Bull & Bear",
  #                "location"=>{"street"=>"431 N Wells St", "city"=>"Chicago", "state"=>"IL", "zip"=>"60654-4512",
  #                             "latitude"=>41.890177, "longitude"=>-87.633815}}  
  def self.import_facebook_place(hash)
    # normalize place hash
    @hash = Hash['name' => hash['name'], 'address' => hash['location']['street'], 'city' => hash['location']['city'],
                 'state' => hash['location']['state'], 'zip' => hash['location']['zip'],
                 'lat' => hash['location']['latitude'], 'lng' => hash['location']['longitude']]
    import_venue(hash['id'].to_s, Source.facebook, @hash)
  end

  def self.import_venue(id, type, hash)
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
    @location = self.add(@hash)
    # add location source
    @location.location_sources.create(:source_id => id.to_s, :source_type => type)
    
    log(:ok, "added location #{@location.name}")
    
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
    CHECKINS_LOGGER.debug("#{Time.now}: [#{level}] #{s}")
  end

end