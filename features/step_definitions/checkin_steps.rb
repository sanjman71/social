Given /^user "([^"]*)" checked in to "([^"]*)" "([^"]*)"$/ do |handle, location_name, checkin_at|
  user      = User.find_by_handle!(handle)
  location  = Location.find_by_name!(location_name)
  checkin   = user.checkins.create!(Factory.attributes_for(:foursquare_checkin, :location => location,
                                                           :checkin_at => Chronic.parse(checkin_at)))
end

Given /^planned checkin reminders are sent$/ do
  User.all.each do |user|
    user.send_planned_checkin_reminders
  end
end

Given /^planned checkins are expired$/ do
  PlannedCheckin.expire_all
end

Given /^the realtime checkin stream job is queued$/ do
  Resque.enqueue(CheckinWorker, :search_realtime_checkin_matches)
end

