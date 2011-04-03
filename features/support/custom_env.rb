# deprecated
# require 'cucumber/thinking_sphinx/external_world'
# Cucumber::ThinkingSphinx::ExternalWorld.new

require 'email_spec'
require 'email_spec/cucumber'
require 'webmock/cucumber'

module LocalityWorld
  def init_states_and_cities
    # add default states and cities
    ca = State.find_or_create_by_name(:name => 'California', :code => 'CA', :country => Country.us)
    il = State.find_or_create_by_name(:name => 'Illinois', :code => 'IL', :country => Country.us)
    ma = State.find_or_create_by_name(:name => 'Massachusetts', :code => 'MA', :country => Country.us)
    ny = State.find_or_create_by_name(:name => 'New York', :code => 'NY', :country => Country.us)
    chicago = City.find_or_create_by_name(:name => 'Chicago', :state => il, :lat => 41.8781136, :lng => -87.6297982)
  end
end

World(LocalityWorld)

Before do
  WebMock.allow_net_connect!
  RedisSocket.reset!
  Resque.reset!
  Timecop.return
  OmniAuth.config.test_mode = true
  # deprecated
  # ThinkingSphinx::Test.index
  Badges::Init.add_roles_and_privileges
  init_states_and_cities
end

After do
  Timecop.return
  OmniAuth.config.test_mode = false
end
