When /^I wait for "([^"]*)" second(?:s)$/ do |seconds|
  sleep(seconds.to_f)
end

When /^(\d+) days have passed/ do |days|
  Timecop.return
  Timecop.travel(days.to_i.days.from_now)
end