When /^the delayed jobs are processed$/ do
  worker = Delayed::Worker.new(:quiet => true)
  while (Delayed::Job.count > 0) do
    # work off jobs and check again
    worker.work_off(Delayed::Job.count)
  end
end

When /^the delayed jobs are deleted$/ do
  Delayed::Job.delete_all
end
