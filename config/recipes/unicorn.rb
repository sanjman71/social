namespace :unicorn do
  
  desc "Start the unicorn app server"
  task :start, :roles => :app do
    run "/etc/init.d/unicorn start"
  end

  desc "Stop the unicorn app server"
  task :stop, :roles => :app do
    run "/etc/init.d/unicorn stop"
  end

  desc "Restart the unicorn app server"
  task :restart, :roles => :app do
    run "/etc/init.d/unicorn reload"
  end

end