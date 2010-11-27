When /^I wait "([^"]*)" second(?:s)$/ do |seconds|
  sleep(seconds.to_f)
end
