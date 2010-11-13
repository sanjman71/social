Given /^a user "([^"]*)" in "([^"]*)" who is a "([^"]*)" "([^"]*)"$/ do |handle, city_state, orientation, gender|
  match   = city_state.match(/^(.*), (.*)$/)
  state   = State.find_by_code!(match[2])
  city    = City.find_or_create_by_name(:name => match[1], :state => state)
  user    = User.find_or_create_by_handle(:handle => handle, :city => city, :orientation => orientation,
                                          :gender => gender, :password => 'secret', :password_confirmation => 'secret')
end

Given /^a user "([^"]*)" with "([^"]*)" dollars$/ do |handle, amount|
  user = User.find_by_handle!(handle)
  user.update_attribute(:points, amount)
end

Given /^I am logged in as "([^"]*)"$/ do |handle|
  And %{I go to beta page}
  And %{I fill in "code" with "applepie"}
  And %{I press "Continue"}

  And %{I go to login page}
  And %{I fill in "user_handle" with "#{handle}"}
  And %{I fill in "user_password" with "secret"}
  And %{I press "Sign in"}
end
