# oauth (default) login
Given /^I am logged in as "([^"]*)"$/ do |handle|
  # oauth login
  # And %{I go to #{handle}'s outlately oauth page}
  And %{outlately authorizes me as "#{handle}"}
end

# password login
Given /^I am password logged in as "([^"]*)"$/ do |handle|
  # user, password login
  And %{I go to login password page}
  And %{I fill in "user_handle" with "#{handle}"}
  And %{I fill in "user_password" with "secret"}
  And %{I press "Sign in"}
end

# Given /^I enter the beta password$/ do
#   And %{I go to beta page}
#   And %{I fill in "code" with "applepie"}
#   And %{I press "Continue"}
# end

When /^the facebook mock oauth has user "([^"]*)" and email "([^"]*)" and id "([^"]*)"$/ do |name, email, id|
  first = name.split[0].strip
  last  = name.split[1].strip
  OmniAuth.config.mock_auth[:facebook] = {
    'provider' => 'facebook',
    'credentials'=> {'token'=>'114293108648736'},
    'extra' => {'user_hash' =>
      {'email' => email, 'id' => id, 'nickname'=>name, 'first_name'=>first, 'last_name'=>last, 'name'=>name}}
  }
end

Given /^outlately authorizes me as "([^"]*)"$/ do |handle|
  user = User.find_by_handle(handle)
  visit '/users/auth/outlately/callback?handle=' + user.id.to_s
end
