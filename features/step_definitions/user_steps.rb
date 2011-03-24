# add user city
Given /^user "([^"]*)" has city "([^"]*)"$/ do |handle, city|
  user  = User.find_by_handle!(handle)
  city  = City.find_by_name(city)
  user.city = city
  user.save
end

# add user admin role
Given /^user "([^"]*)" is an admin$/ do |handle|
  user = User.find_by_handle!(handle)
  user.grant_role('admin')
end

# add user email address
Given /^user "([^"]*)" has email "([^"]*)"$/ do |handle, email|
  user = User.find_by_handle!(handle)
  user.email_addresses_attributes = [{:address => email}]
  user.save
end

# add user birthdate
Given /^user "([^"]*)" has birthdate "([^"]*)"$/ do |handle, birthdate|
  user = User.find_by_handle!(handle)
  date = Date.parse(birthdate)
  user.birthdate = date
  user.save
end

# add user oauth
Given /^user "([^"]*)" has oauth "([^"]*)" "([^"]*)"$/ do |handle, provider, token|
  user  = User.find_by_handle!(handle)
  oauth = user.oauths.create!(:provider => provider, :access_token => token)
end

# add user friend
Given /^"([^"]*)" is friends with "([^"]*)"$/ do |handle1, handle2|
  user    = User.find_by_handle!(handle1)
  friend  = User.find_by_handle!(handle2)
  user.friendships.create!(:friend => friend)
end

# add user follow
Given /^"([^"]*)" is following "([^"]*)"$/ do |handle1, handle2|
  user1 = User.find_by_handle!(handle1)
  user2 = User.find_by_handle!(handle2)
  user1.follow(user2)
end

# set user preference
Given /^user "([^"]*)" has preference "([^"]*)" "([^"]*)"$/ do |handle, preference, value|
  user = User.find_by_handle!(handle)
  user.send(preference+"=", value)
  user.save
end

# add user learn
Given /^"([^"]*)" want to learn more about "([^"]*)"$/ do |handle1, handle2|
  user1 = User.find_by_handle!(handle1)
  user2 = User.find_by_handle!(handle2)
  user1.learns_add(user2)
end

# set user points
Given /^a user "([^"]*)" with "([^"]*)" dollars$/ do |handle, points|
  user = User.find_by_handle!(handle)
  user.update_attribute(:points, points)
end

# set user available now
Given /^"([^"]*)" marked themselves as available now$/ do |handle|
  user = User.find_by_handle!(handle)
  user.availability_attributes = {:now => 1}
  user.save
end

# user invited another user
Given /^user "([^"]*)" invited "([^"]*)"$/ do |handle, email|
  user = User.find_by_handle!(handle)
  user.invitations.create!(:recipient_email => email)
end

Given /^user "([^"]*)" poked "([^"]*)" to invite "([^"]*)"$/ do |poker_handle, friend_handle, invitee_handle|
  poker   = User.find_by_handle!(poker_handle)
  invitee = User.find_by_handle!(invitee_handle)
  friend  = User.find_by_handle!(friend_handle)
  poke    = InvitePoke.find_or_create(invitee, poker)
end

# add any missing user badges
Given /^user badge discovery is run$/ do
  User.all.each do |user|
    user.async_add_badges
  end
end

