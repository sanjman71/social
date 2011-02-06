When /^I wait for "(\d+)" second|seconds$/ do |seconds|
  sleep(seconds.to_f)
end

When /^(\d+) day|days have passed/ do |days|
  Timecop.return
  Timecop.travel(days.to_i.days.from_now)
end

When /^(\d+) hour|hours have passed/ do |hours|
  Timecop.return
  Timecop.travel(hours.to_i.hours.from_now)
end