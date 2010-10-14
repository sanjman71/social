source 'http://rubygems.org'

gem 'rails', '3.0.0'

# Mysql gem for ruby 1.9.2
gem 'ruby-mysql'

gem 'aasm',                   '>= 2.2.0'
gem 'acts-as-taggable-on',    '>= 2.0.6'
# crack version that fixes parser errors by using ActiveSupport yaml parser
gem 'crack',                  :git => 'git://github.com/sanjman71/crack.git'
gem 'daemons',                '1.0.10' # dj doesn't start with 1.1.0
gem 'delayed_job',            :git => 'git://github.com/collectiveidea/delayed_job.git'
gem 'foursquare',             '>= 0.3.1'
gem 'geokit',                 '>= 1.5.0'
# hashie required by foursquare gem
gem 'hashie',                 '>= 0.3.1'
gem 'httparty',               '0.4.3' # older version required by foursquare gem
gem 'haml',                   '>= 3.0.18'
gem 'devise',                 :git => 'git://github.com/plataformatec/devise.git' # devise with oauth support
gem 'oauth',                  '>= 0.4.2'
gem 'oauth2',                 '>= 0.0.13'
gem 'ts-delayed-delta',       '>= 1.1.0'
gem 'test-unit',              '>= 2.1.1'  # used by teamcity
gem 'unicorn',                '>= 1.1.3'
gem 'thinking-sphinx',        '>=2.0.0.rc1', :require => 'thinking_sphinx'  
gem 'whenever',               '>= 0.5.0'


# Bundle gems for the local environment. Make sure to
# put test-only gems in this group so their generators
# and rake tasks are available in development mode:
group :development, :test do
  gem 'capistrano'
  gem 'shoulda'
  gem 'mocha'
  gem 'factory_girl_rails'
  gem 'linecache19'
  gem 'ruby-debug19'
  gem 'single_test'
end
