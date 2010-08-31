# Be explicit about our different environments
set :stages, %w(production staging)
require 'capistrano/ext/multistage'

# Set application name
set :application,   "social"

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
# load "bundle"
# load "delayed_job"
# load "memcached"
# load "sphinx"

# automatically called after a deploy
deploy.task :restart, :roles => :app do
  run "touch #{current_release}/tmp/restart.txt"
end

# after deploy task
deploy.task :config, :roles => [:app, :db] do
  run "cp -u #{current_release}/config/templates/database.#{rails_env}.yml #{deploy_to}/shared/config/database.yml"
  run "rm -f #{current_release}/config/database.yml"
  run "ln -s #{deploy_to}/shared/config/database.yml #{current_release}/config/database.yml"
  run "rm -f #{current_release}/config/production.sphinx.conf"
  run "ln -s #{deploy_to}/shared/config/production.sphinx.conf #{current_release}/config/production.sphinx.conf"
end

# after deploy
after "deploy", "deploy:config"
after "deploy", "bundle:config"
after "deploy", "deploy:cleanup"

after "deploy:stop",  "dj:stop"
after "deploy:start", "dj:start"

# after deploy:setup
deploy.task :init, :roles => :app do
  sudo "chown -R #{user}:#{group} #{deploy_to}"
  run "mkdir -p #{deploy_to}/shared"
  run "mkdir -p #{deploy_to}/shared/config"
  run "mkdir -p #{deploy_to}/shared/vendor/bundle"
end

after "deploy:setup", "deploy:init"
