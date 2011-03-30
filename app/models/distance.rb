class Distance
  include Geokit::Mappable

  # calculate the checkin distance between the user and the specified checkin
  def self.checkin_distance(user, checkin, options={})
    user_latlng    = [user.city.lat, user.city.lng]
    checkin_latlng = [checkin.location.lat, checkin.location.lng]
    distance_between(user_latlng, checkin_latlng, :units => :miles)
  end
end