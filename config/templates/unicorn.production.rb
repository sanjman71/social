# See http://unicorn.bogomips.org/Unicorn/Configurator.html for complete documentation.
# usage: unicorn_rails -c /usr/apps/social/current/config/unicorn.rb -E production -D

rails_env = ENV['RAILS_ENV'] || 'production'
if rails_env == 'development'
  app_path    = File.expand_path('.')
  shared_path = "#{app_path}"
else
  # default
  app_path    = '/usr/apps/social/current'
  shared_path = '/usr/apps/social/shared'
end

worker_processes 3

user 'app', 'app'

# Help ensure your application will always spawn in the symlinked
# "current" directory that Capistrano sets up.
working_directory "/usr/apps/social/current"

# Listen on a Unix data socket
listen "#{shared_path}/sockets/unicorn.sock", :backlog => 64

# listen on both a Unix domain socket and a TCP port,
# we use a shorter backlog for quicker failover when busy
# listen "/tmp/shop.socket", :backlog => 64

# nuke workers after 30 seconds instead of 60 seconds (the default)
timeout 30

# feel free to point this anywhere accessible on the filesystem
pid "#{shared_path}/pids/unicorn.pid"
stderr_path "#{shared_path}/log/unicorn.stderr.log"
stdout_path "#{shared_path}/log/unicorn.stdout.log"