When /^I wait for "([^"]*)" second(?:s)$/ do |seconds|
  sleep(seconds.to_f)
end
