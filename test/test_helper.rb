ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'test/unit'
require 'shoulda'
require 'mocha' # require mocha after shoulda and test/unit
require 'factories'
require 'thinking_sphinx/test'
require 'timecop'
require 'fast_context'

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

  def assert_nil(x)
    assert_equal nil, x
  end

  def setup_badges
    Badges::Init.add_roles_and_privileges
  end

  def match_delayed_jobs(regex)
    Delayed::Job.all.select{ |dj| dj.handler.match(regex) }.size
  end

  def work_off_delayed_jobs(regex=nil)
    if regex
      # delete jobs not matching regex
      Delayed::Job.all.each { |dj| dj.handler.match(regex) ? nil : dj.delete }
    end
    @worker ||= Delayed::Worker.new(:quiet => true)
    @worker.work_off(Delayed::Job.count)
  end
end
