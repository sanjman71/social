module LocalityWorld
  # add default states, cities
  ca = State.find_or_create_by_name(:name => 'California', :code => 'CA', :country => Country.us)
  il = State.find_or_create_by_name(:name => 'Illinois', :code => 'IL', :country => Country.us)
  ma = State.find_or_create_by_name(:name => 'Massachusetts', :code => 'MA', :country => Country.us)
  ny = State.find_or_create_by_name(:name => 'New York', :code => 'NY', :country => Country.us)
  
  chicago = City.find_or_create_by_name(:name => 'Chicago', :state => il, :lat => 41.8781136, :lng => -87.6297982)
end

World(LocalityWorld)

Given /^a user "([^"]*)" in "([^"]*)" who is a "([^"]*)" "([^"]*)"$/ do |handle, city_state, orientation, gender|
  match   = city_state.match(/^(.*), (.*)$/)
  state   = State.find_by_code!(match[2])
  city    = City.find_or_create_by_name(:name => match[1], :state => state)
  user    = User.find_or_create_by_handle(:handle => handle, :city => city, :orientation => orientation,
                                          :gender => gender, :password => 'secret', :password_confirmation => 'secret')
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
