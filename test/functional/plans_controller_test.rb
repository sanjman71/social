require 'test_helper'

class PlansControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  context "routes" do
    should route(:put, 'plans/add').to(:controller => 'plans', :action => 'add')
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
    should "add location to todo list" do
      @user1 = Factory.create(:user, :handle => 'User1', :city => @chicago)
      sign_in @user1
      set_beta
      put :add, :location_id => @sbux.id
      assert_equal 1, @user1.reload.locationships.count
      assert_equal [@sbux.id], @user1.reload.locationships.collect(&:location_id)
      assert_equal [1], @user1.reload.locationships.collect(&:todo_checkins)
      assert @user1.reload.locationships.first.todo_at
      # should add growl message
      assert_equal 1, assigns(:growls).size
      assert_redirected_to '/'
    end

    should "create location and add location to todo list" do
      @user1 = Factory.create(:user, :handle => 'User1', :city => @chicago)
      sign_in @user1
      set_beta
      put :add, :location => {:name => "Inteligentsia Coffee",
                              :source => "foursquare:44123",
                              :address => "53 W. Jackson Blvd.",
                              :city_state => "Chicago:IL",
                              :lat => "41.877901218486535",
                              :lng => "-87.62948513031006"}
      assert_equal 1, @user1.reload.locationships.count
      # should create location
      assert assigns(:location)
      assert_equal [assigns(:location).id], @user1.reload.locationships.collect(&:location_id)
      assert_equal [1], @user1.reload.locationships.collect(&:todo_checkins)
      assert @user1.reload.locationships.first.todo_at
      # should add growl message
      assert_equal 1, assigns(:growls).size
      assert_redirected_to '/'
    end

    should "ignore if location already on todo list" do
      @user1 = Factory.create(:user, :handle => 'User1', :city => @chicago)
      @user1.locationships.create!(:location => @sbux, :todo_checkins => 1)
      assert_equal [@sbux.id], @user1.reload.locationships.collect(&:location_id)
      assert_equal [1], @user1.reload.locationships.collect(&:todo_checkins)
      sign_in @user1
      set_beta
      put :add, :location_id => @sbux.id
      assert_equal [@sbux.id], @user1.reload.locationships.collect(&:location_id)
      assert_equal [1], @user1.reload.locationships.collect(&:todo_checkins)
      assert_redirected_to '/'
    end

    should "ignore if location already checked in to" do
      @user1 = Factory.create(:user, :handle => 'User1', :city => @chicago)
      @user1.locationships.create!(:location => @sbux, :my_checkins => 1)
      sign_in @user1
      set_beta
      put :add, :location_id => @sbux.id
      assert_equal [@sbux.id], @user1.reload.locationships.collect(&:location_id)
      assert_equal [0], @user1.reload.locationships.collect(&:todo_checkins)
      assert_redirected_to '/'
    end
  end
  
end
