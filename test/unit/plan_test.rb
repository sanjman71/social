require 'test_helper'

class PlanTest < ActiveSupport::TestCase
  
  def setup
    @us           = Factory(:us)
    @canada       = Factory(:canada)
    @il           = Factory(:il, :country => @us)
    @on           = Factory(:ontario, :country => @canada)
    @chicago      = Factory(:chicago, :state => @il, :timezone => Factory(:timezone_chicago))
    @toronto      = Factory(:toronto, :state => @on)
    @user         = Factory.create(:user)
    @starbucks    = Location.create!(:name => 'Starbucks', :city => @chicago, :state => @il, :country => @us)
  end
  
  should "create unique plan" do
    # user plans a location
    @user.planned_locations.push(@starbucks)
    assert_equal 1, @user.reload.plans.count
    assert_equal [@starbucks], @user.planned_locations
    # should not allow duplicate plan
    assert_raise ActiveRecord::RecordInvalid do
      @user.planned_locations.push(@starbucks)
    end
  end

end
