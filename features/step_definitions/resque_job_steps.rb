When /^the resque jobs are processed(?: again)?$/ do
  Resque.run!
end

When /^the resque jobs are processed until empty?$/ do
  Resque.full_run!
end

When /^the resque jobs are cleared|reset$/ do
  Resque.reset!
end
