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

ACCESS_TOKEN = {
  :access_token => "outlately"
}

FACEBOOK_INFO = {
  :id => '12345',
  :link => 'http://facebook.com/facebook_guy',
  :email => 'facebook_guy@gmail.com',
  :first_name => 'First',
  :last_name => 'Last',
  :website => 'http://outlate.ly'
}

Then /^outlately authorizes me as "([^"]*)"$/ do |handle|
  Devise::OmniAuth.short_circuit_authorizers!
  Devise::OmniAuth.stub!(:outlately) do |b|
    b.post('/oauth/access_token') { [200, {}, ACCESS_TOKEN.to_json] }
  end
  visit '/users/auth/outlately/callback?handle=' + handle
end

Then /^I login with facebook as "([^"]*)"$/ do |handle|
  # map handle to user, if one exists
  user = User.find_by_handle(handle)
  # set facebook oauth data
  FACEBOOK_INFO[:link] = "http://facebok.com/#{handle}"
  if user
    # link handle to authenticating facebook user
    FACEBOOK_INFO[:id] = user.facebook_id
  end
  Devise::OmniAuth.short_circuit_authorizers!
  Devise::OmniAuth.stub!(:facebook) do |b|
    b.post('/oauth/access_token') { [200, {}, ACCESS_TOKEN.to_json] }
    b.get('/me?access_token=outlately') { [200, {}, FACEBOOK_INFO.to_json] }
  end
  visit '/users/auth/facebook/callback'
end
