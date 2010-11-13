Given /^"([^"]*)" checked in to "([^"]*)" in "([^"]*)"$/ do |handle, location_name, city_name|
  user      = User.find_by_handle!(handle)
  city      = City.find_by_name!(city_name)
  location  = Location.find_or_create_by_name(:name => location_name, :city => city, :lat => city.lat, :lng => city.lng)
  # create checkin and locationship
  checkin   = user.checkins.create!(Factory.attributes_for(:foursquare_checkin, :location => location))
  locship   = user.locationships.find_or_create_by_location_id(location.id)
  locship.increment!(:my_checkins)
end

