# oauth (default) login
Given /^I am logged in as "([^"]*)"$/ do |handle|
  And %{I go to beta page}
  And %{I fill in "code" with "applepie"}
  And %{I press "Continue"}

  # oauth login
  And %{I go to #{handle}'s outlately oauth page}
end

# password login
Given /^I am password logged in as "([^"]*)"$/ do |handle|
  And %{I go to beta page}
  And %{I fill in "code" with "applepie"}
  And %{I press "Continue"}

  # user, password login
  And %{I go to login password page}
  And %{I fill in "user_handle" with "#{handle}"}
  And %{I fill in "user_password" with "secret"}
  And %{I press "Sign in"}
end

