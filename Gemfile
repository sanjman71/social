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
gem 'devise',                 '>= 1.2.rc'
gem 'dotiw',                  '>= 0.4.1'
gem 'foursquare',             '>= 0.3.1'
gem 'geokit',                 '>= 1.5.0'
gem 'groupme-paddock',        '>= 0.3.1', :require => 'paddock'
gem 'httparty',               '>= 0.6.1'
gem 'haml',                   '>= 3.0.18'
gem 'haml-rails',             '>= 0.3.4'
gem 'high_voltage'
gem 'jquery-rails',           '>= 0.2.6'
gem 'juggernaut'
gem 'less',                   '>= 1.2.21'
gem 'meta_where',             '>= 0.9.6'
gem 'oa-oauth',               :require => "omniauth/oauth"
gem 'omniauth',               '>= 0.1.6'
gem 'RedCloth',               '>= 4.2.3'
gem 'resque',                 '>= 1.10.0'
gem 'simple_form',            '>= 1.2.2'
gem "SyslogLogger",           ">= 1.4.0"
gem 'ts-delayed-delta',       :git => 'git://github.com/freelancing-god/ts-delayed-delta.git'
gem 'test-unit',              '>= 2.1.1'  # used by teamcity
gem 'thor',                   '>= 0.14.6'
gem 'thinking-sphinx',        '>= 2.0.0', :require => 'thinking_sphinx'
gem 'twitter',                '>= 1.0.0'
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
  gem 'pickle',                 '>= 0.4.3'
  gem 'random_data'
  gem 'rspec-rails',  :require => nil
  gem 'ruby-debug19'
  gem 'shoulda', :require => nil
  gem 'single_test'
  gem 'timecop', '>= 0.3.5'
end

platforms :ruby_19 do
  gem 'linecache19' # used by ruby debug
  gem 'ruby-debug19'
end
