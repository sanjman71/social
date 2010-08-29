class FoursquareCheckin
  
  # import a foursquare checkin hash
  # e.g. {"id"=>141731194, "created"=>"Sun, 22 Aug 10 23:16:33 +0000", "timezone"=>"America/Chicago",
  #       "venue"=>{"id"=>4172889, "name"=>"Zed 451", "address"=>"763 N. Clark St.", "city"=>"Chicago", "state"=>"Illinois",
  #                 "geolat"=>41.8964066, "geolong"=>-87.6312161}
  #      }
  def self.import_checkin(user, checkin_hash)
    # map foursquare venue to a location
    @location = LocationImport.import_foursquare_venue(checkin_hash['venue'])
    if @location.blank?
      raise Exception, "invalid location #{checkin_hash['venue']}"
    end
    
    # add checkin
    options  = Hash[:location => @location, :checkin_at => Time.zone.now, :source_id => checkin_hash['id'].to_s, :source_type => Source.foursquare_type]
    @checkin = user.checkins.find_by_source_id_and_source_type(options[:source_id], options[:source_type])
    @checkin ||= user.checkins.create(options)
  end
  
end