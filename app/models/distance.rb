class Distance
  include Geokit::Mappable

  # calculate the checkin distance between the user and the specified checkin
  def self.checkin_distance(geo, checkin, options={})
    source_latlng   = [geo.lat, geo.lng]
    checkin_latlng  = [checkin.location.lat, checkin.location.lng]
    distance_between(source_latlng, checkin_latlng, :units => :miles)
  rescue Exception => e
    log("[distance] distance between error #{e.message}, defaulting to 0.0")
    0.0
  end

  def self.log(s, level = :info)
    AppLogger.log(s, nil, level)
  end

end