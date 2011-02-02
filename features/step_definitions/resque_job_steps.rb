When /^the resque jobs are processed$/ do
  Resque.run!
end

When /^the resque jobs are cleared|reset$/ do
  Resque.reset!
end
