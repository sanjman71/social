class LocationImport

  # import a foursquare venue location hash
  # e.g. "venue"=>{"id"=>4172889, "name"=>"Zed 451", "address"=>"763 N. Clark St.", "city"=>"Chicago", "state"=>"Illinois",
  #                "geolat"=>41.8964066, "geolong"=>-87.6312161}
  def self.import_foursquare_venue(venue_hash)
    # check for matching locations using venue id
    @locations = Location.joins(:location_sources) & LocationSource.with_source_id(venue_hash['id']).with_source_type('fs')
    return @locations.first if @locations.size == 1

    # check for matching locations using venue info
    @hash      = Hash['name' => venue_hash['name'], 'address' => venue_hash['address'], 'city' => venue_hash['city'],
                      'state' => venue_hash['state'], 'lat' => venue_hash['geolat'], 'lng' => venue_hash['geolong']]
    @locations = LocationFinder.match(@hash)
    return @locations.first if @locations.size == 1

    if @locations.size > 1
      # xxx - we found more than 1 matching location
      return nil
    end

    # add new location
    @location = self.add(@hash)
    # add location source
    @location.location_sources.create(:source_id => venue_hash['id'], :source_type => 'fs')
    
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

end