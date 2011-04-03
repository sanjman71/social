$:.unshift(File.expand_path('./lib', ENV['rvm_path'])) # Add RVM's lib directory to the load path.
require "rvm/capistrano"
set :rvm_ruby_string, '1.9.2'
set :rvm_type,        :user  # don't use system-wide RVM

# Be explicit about our different environments
set :stages, %w(production)
require 'capistrano/ext/multistage'

require "bundler/capistrano"

# Set application name
set :application,   "outlately"

# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
set :deploy_to,     "/usr/apps/#{application}"

# Git repository
set :scm,           :git
set :repository,    'git@github.com:sanjman71/social.git'
set :branch,        "master"
set :deploy_via,    :remote_cache

# Users, groups
set :user,          'app'  # log into servers as
set :group,         'app'

ssh_options[:forward_agent] = true
default_run_options[:pty] = true

# Load external recipe files
load_paths << "config/recipes"
# load "delayed_job"
load "resque_worker"
# load "sphinx"

# automatically called after a deploy
deploy.task :restart, :roles => :app do
  run "touch #{current_release}/tmp/restart.txt"
end

# after deploy:update_code task
deploy.task :config, :roles => [:app, :db] do
  run "cp -u #{current_release}/config/templates/database.#{rails_env}.yml #{deploy_to}/shared/config/database.yml"
  run "rm -f #{current_release}/config/database.yml"
  run "ln -s #{deploy_to}/shared/config/database.yml #{current_release}/config/database.yml"
  run "rm -f #{current_release}/config/unicorn.rb"
  run "ln -s #{deploy_to}/shared/config/unicorn.rb #{current_release}/config/unicorn.rb"
  # run "rm -f #{current_release}/config/production.sphinx.conf"
  # run "ln -s #{deploy_to}/shared/config/production.sphinx.conf #{current_release}/config/production.sphinx.conf"
  run "rm -rf #{current_release}/tmp/sockets"
  run "ln -s #{deploy_to}/shared/sockets #{current_release}/tmp/sockets"
end

# after deploy update_code
after "deploy:update_code", "deploy:config"

# after deploy
# after "deploy", "dj:restart"
after "deploy", "rw:restart"
after "deploy", "deploy:cleanup"

# after deploy stop/start
# after "deploy:stop",  "dj:stop"
# after "deploy:start", "dj:start"
after "deploy:stop",  "rw:stop"
after "deploy:start", "rw:start"

# after deploy:setup
deploy.task :init, :roles => :app do
  sudo "chown -R #{user}:#{group} #{deploy_to}"
  run "mkdir -p #{deploy_to}/shared"
  run "mkdir -p #{deploy_to}/shared/backups"
  run "mkdir -p #{deploy_to}/shared/bundle"
  run "mkdir -p #{deploy_to}/shared/config"
  run "mkdir -p #{deploy_to}/shared/pids"
  run "mkdir -p #{deploy_to}/shared/sockets"
  run "mkdir -p #{deploy_to}/shared/sphinx"
end

after "deploy:setup", "deploy:init"
