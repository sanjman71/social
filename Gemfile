source 'http://rubygems.org'

gem 'rails', '3.0.0'

# Mysql gem for ruby 1.9.2
gem 'ruby-mysql'

gem 'aasm',                   '>= 2.2.0'
gem 'acts-as-taggable-on',    '>= 2.0.6'
gem 'alchemist',              '>= 0.1.2'
# crack version that fixes parser errors by using ActiveSupport json parser
gem 'crack',                  :git => 'git://github.com/sanjman71/crack.git'
gem 'daemons',                '1.0.10' # dj doesn't start with 1.1.0
gem 'delayed_job',            :git => 'git://github.com/collectiveidea/delayed_job.git'
gem 'devise',                 :git => 'git://github.com/plataformatec/devise.git' # devise with oauth support
gem 'foursquare',             '>= 0.3.1'
gem 'geokit',                 '>= 1.5.0'
gem 'groupme-paddock',        '>= 0.3.1', :require => 'paddock'
gem 'httparty',               '>= 0.6.1'
gem 'haml',                   '>= 3.0.18'
gem 'haml-rails'
gem 'meta_where',             '>= 0.9.6'
gem 'oauth',                  '>= 0.4.2'
gem 'oauth2',                 '>= 0.0.13'
gem 'resque',                 '>= 1.10.0'
gem 'simple_form',            '>= 1.2.2'
gem "SyslogLogger",           ">= 1.4.0"
gem 'ts-delayed-delta',       '>= 1.1.1'
gem 'test-unit',              '>= 2.1.1'  # used by teamcity
gem 'thor',                   '>= 0.14.6'
gem 'thinking-sphinx',        '>= 2.0.0', :require => 'thinking_sphinx'
gem 'will_paginate',          '3.0.pre2'
gem 'whenever',               '>= 0.5.0'

# Bundle gems for the local environment. Make sure to
# put test-only gems in this group so their generators
# and rake tasks are available in development mode:
group :development, :test do
  gem 'capistrano'
  gem 'capybara'
  gem 'cucumber'
  gem 'cucumber-rails'
  gem 'database_cleaner'
  gem 'email_spec',             '>= 1.0.0', :require => nil
  gem 'factory_girl_rails'
  gem 'launchy'
  gem 'linecache19'
  gem 'mocha', :require => nil
  gem 'random_data'
  gem 'rspec-rails',  :require => nil
  gem 'ruby-debug19'
  gem 'shoulda', :require => nil
  gem 'single_test'
  gem 'timecop', '>= 0.3.5'
end
