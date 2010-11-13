Then /^I should see user "([^"]*)" in stream "([^"]*)"$/ do |handle, stream|
  # should have 'stream' marked as current stream
  page.has_selector?("span.stream_name.current", :text => stream.titleize)
  # should have user checkin in stream
  assert page.has_selector?("div#checkin_user_location", :text => handle)
end
