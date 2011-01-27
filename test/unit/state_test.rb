require 'test_helper'

class StateTest < ActiveSupport::TestCase
  should belong_to :country
  should have_many :cities
  should have_many :locations
  
  context "state" do
    context "illinos" do
      setup do
        @il = states(:il)
      end
      
      should "have to_s method return Illinois" do
        assert_equal "Illinois", @il.to_s
      end
      
      should "have to_param method return il" do
        assert_equal "il", @il.to_param
      end
    end
  end
end
