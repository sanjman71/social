ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'factories'
require 'thinking_sphinx/test'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  # fixtures :all

  def set_beta
    session[:beta] = 1
  end

  # Add more helper methods to be used by all tests here...
  def assert_true(x)
    assert(x)
  end

  def assert_false(x)
    assert(!x)
  end

  def assert_not_valid(x)
    assert !x.valid?
  end  

  def assert_nil(x)
    assert_equal nil, x
  end
end
