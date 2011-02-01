# Capistrano Recipes for managing resque_worker
#
# Add these callbacks to have the delayed_job process restart when the server
# is restarted:
#
#   after "deploy:stop",    "resque_worker:stop"
#   after "deploy:start",   "resque_worker:start"

namespace :rw do
  desc "Stop the resque_worker process"
  task :stop, :roles => :resque do
    run "bash -ic 'cd #{current_path} && script/resque_worker stop'"
  end

  desc "Start the resque_worker process"
  task :start, :roles => :resque do
    run "bash -ic 'cd #{current_path} && script/resque_worker start'"
  end

  desc "Restart the resque_worker process"
  task :restart, :roles => :resque do
    # stop and then start; restart doesn't work properly
    stop
    sleep(3)
    start
  end
end