# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)
require 'rake'

Social::Application.load_tasks

begin
  require 'delayed/tasks'
rescue LoadError
  STDERR.puts "Run `bundle install` to install delayed_job"
end

begin
  require 'single_test'
  SingleTest.load_tasks
rescue LoadError
  # ignore
end
