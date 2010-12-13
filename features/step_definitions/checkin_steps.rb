Given /^"([^"]*)" checked in to "([^"]*)" in "([^"]*)"(?: about "([^"]*)")?$/ do |handle, location_name, city_name, time_ago|
  user      = User.find_by_handle!(handle)
  city      = City.find_by_name!(city_name)
  location  = Location.find_or_create_by_name(:name => location_name, :city => city, :lat => city.lat, :lng => city.lng)
  # create checkin and locationship
  if time_ago
    # set checkin timestamp
    checkin_at = eval(time_ago.gsub(' ', '.'))
  else
    # make it a recente checkin
    checkin_at = 1.minute.ago
  end
  checkin   = user.checkins.create!(Factory.attributes_for(:foursquare_checkin, :location => location,
                                                           :checkin_at => checkin_at))
  locship   = user.locationships.find_or_create_by_location_id(location.id)
  locship.increment!(:my_checkins)
end

Given /^user "([^"]*)" checked in to "([^"]*)"(?: when "([^"]*)")?$/ do |handle, location_name, checkin_at|
  user      = User.find_by_handle!(handle)
  location  = Location.find_by_name!(location_name)
  if !checkin_at
    # make it a recente checkin
    checkin_at = 1.minute.ago
  end
  checkin   = user.checkins.create!(Factory.attributes_for(:foursquare_checkin, :location => location,
                                                           :checkin_at => checkin_at))
  locship   = user.locationships.find_or_create_by_location_id(location.id)
  locship.increment!(:my_checkins)
end


