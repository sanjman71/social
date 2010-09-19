source 'http://rubygems.org'

gem 'rails', '3.0.0'

# Mysql gem for ruby 1.9.2
gem 'ruby-mysql'

gem 'aasm',                   '>= 2.2.0'
gem 'delayed_job'
gem 'foursquare'
gem 'geokit',                 '>= 1.5.0'
# hashie required by foursquare gem
gem 'hashie'                
gem 'httparty',               '0.4.3' # older version required by foursquare gem
gem 'haml',                   '>= 3.0.18'
gem 'devise',                 :git => 'git://github.com/plataformatec/devise.git' # devise with oauth support
# gem 'devise',                 '>= 1.1.2'
gem 'oauth'
gem 'oauth2'
gem 'ts-delayed-delta',       '>= 1.1.0'
gem 'unicorn'
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
