namespace :ci do
  
  desc "Run bundle install on a CI server"
  task :bundle do
    system("bundle install")
  end

  desc "Setup config files on a CI server"
  task :setup do
    system("cd #{Rails.root} && cp config/templates/database.ci.yml config/database.yml")
  end

  desc "Run the Continuous Integration build"
  task :run => ["ci:bundle", "ci:setup", "db:migrate:reset"] do
    Rake::Task[:test].invoke
  end
  
end