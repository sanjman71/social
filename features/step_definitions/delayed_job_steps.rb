When /^the delayed jobs are processed$/ do
  worker = Delayed::Worker.new(:quiet => true)
  worker.work_off(Delayed::Job.count)
end
