require 'test_helper'

class PlansControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  context "routes" do
    should route(:put, 'plans/add/1').to(:controller => 'plans', :action => 'add', :location_id => '1')
    should route(:put, 'plans/remove/1').to(:controller => 'plans', :action => 'remove', :location_id => '1')
  end

  def setup
    @us           = Factory(:us)
    @canada       = Factory(:canada)
    @il           = Factory(:il, :country => @us)
    @on           = Factory(:ontario, :country => @canada)
    @chicago      = Factory(:chicago, :state => @il, :timezone => Factory(:timezone_chicago))
    @toronto      = Factory(:toronto, :state => @on)
    @sbux         = Location.create!(:name => 'Starbucks', :city => @chicago, :country => @us)
  end

  context "add" do
    should "add planned location" do
      @user1 = Factory.create(:user, :handle => 'User1', :city => @chicago)
      sign_in @user1
      set_beta
      put :add, :location_id => @sbux.id
      assert_equal 1, @user1.reload.locationships.count
      assert_equal [@sbux.id], @user1.reload.locationships.collect(&:location_id)
      assert_equal [1], @user1.reload.locationships.collect(&:planned_checkins)
      assert_redirected_to '/'
    end

    should "ignore if location already planned" do
      @user1 = Factory.create(:user, :handle => 'User1', :city => @chicago)
      @user1.locationships.create!(:location => @sbux, :planned_checkins => 1)
      assert_equal [@sbux.id], @user1.reload.locationships.collect(&:location_id)
      assert_equal [1], @user1.reload.locationships.collect(&:planned_checkins)
      sign_in @user1
      set_beta
      put :add, :location_id => @sbux.id
      assert_equal [@sbux.id], @user1.reload.locationships.collect(&:location_id)
      assert_equal [1], @user1.reload.locationships.collect(&:planned_checkins)
      assert_redirected_to '/'
    end
  end
  
end
