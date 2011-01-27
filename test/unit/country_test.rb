require 'test_helper'

class CountryTest < ActiveSupport::TestCase
  should have_many :states
  should have_many :locations

  context "country" do
    context "us" do
      setup do
        @us = countries(:us)
      end
      
      should "have to_s == United States, to_param == 'us'" do
        assert_equal "United States", @us.to_s
        assert_equal "us", @us.to_param
      end
    end
  end
  
end
