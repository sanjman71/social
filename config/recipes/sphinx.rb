namespace :sphinx do
  
  desc "Create the sphinx config file"
  task :configure, :roles => :sphinx do
    run "bash -ic 'cd #{current_path}; rake ts:config'"
  end

  desc "Stop the sphinx searchd daemon"
  task :stop, :roles => :sphinx do
    run "bash -ic 'cd #{current_path}; rake ts:stop'"
  end

  desc "Start the sphinx searchd daemon"
  task :start, :roles => :sphinx do
    run "bash -ic 'cd #{current_path}; rake ts:start'"
  end

  desc "Restart the sphinx searchd daemon"
  task :restart, :roles => :sphinx do
    # stop and then start; restart doesn't work properly
    stop
    sleep(3)
    start
  end

end