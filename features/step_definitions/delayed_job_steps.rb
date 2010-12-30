When /^the delayed jobs are processed$/ do
  worker = Delayed::Worker.new(:quiet => true)
  worker.work_off(Delayed::Job.count)
end

When /^the delayed jobs are deleted$/ do
  Delayed::Job.delete_all
end
