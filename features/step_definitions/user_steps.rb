# find or create user with a location
Given /^a user "([^"]*)" in "([^"]*)" who is a "([^"]*)" "([^"]*)"$/ do |handle, city_state, orientation, gender|
  match   = city_state.match(/^(.*), (.*)$/)
  state   = State.find_by_code!(match[2])
  city    = City.find_or_create_by_name(:name => match[1], :state => state)
  user    = User.find_or_create_by_handle(:handle => handle, :city => city, :orientation => orientation,
                                          :gender => gender, :password => 'secret', :password_confirmation => 'secret')
end

# find or create user without a location
Given /^a user "([^"]*)" who is a "([^"]*)" "([^"]*)"$/ do |handle, orientation, gender|
  user = User.find_or_create_by_handle(:handle => handle, :orientation => orientation,
                                       :gender => gender, :password => 'secret', :password_confirmation => 'secret')
end

# add user email address
Given /^user "([^"]*)" has email "([^"]*)"$/ do |handle, email|
  user = User.find_by_handle!(handle)
  user.email_addresses_attributes = [{:address => email}]
  user.save
end

# add user oauth
Given /^user "([^"]*)" has oauth "([^"]*)"$/ do |handle, provider|
  user  = User.find_by_handle!(handle)
  oauth = user.oauths.create(:provider => provider, :access_token => "111222333")
end


# add user friend
Given /^"([^"]*)" is friends with "([^"]*)"$/ do |handle1, handle2|
  user    = User.find_by_handle!(handle1)
  friend  = User.find_by_handle!(handle2)
  user.friendships.create!(:friend => friend)
end

# set user points
Given /^a user "([^"]*)" with "([^"]*)" dollars$/ do |handle, points|
  user = User.find_by_handle!(handle)
  user.update_attribute(:points, points)
end

# set user available now
Given /^"([^"]*)" marked themselves as available now$/ do |handle|
  user = User.find_by_handle(handle)
  user.availability_attributes = {:now => 1}
  user.save
end
