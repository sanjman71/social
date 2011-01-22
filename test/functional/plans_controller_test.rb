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
    setup do
      @user1 = Factory.create(:user, :handle => 'User1', :city => @chicago)
    end

    should "add planned checkin with default expires_at" do
      sign_in @user1
      set_beta
      put :add, :location_id => @sbux.id
      # should add location to planned checkins list, with default expires_at
      assert_equal 1, @user1.reload.planned_checkins.count
      assert_equal [@sbux], @user1.reload.planned_checkins.collect(&:location)
      assert_equal [7], @user1.reload.planned_checkins.collect{ |o| o.days_left }
      # should add growl message
      assert_equal 1, assigns(:growls).size
      assert_redirected_to '/'
      assert_equal "We added Starbucks to your todo list", flash[:notice]
    end

    should "add planned checkin with expires_at tomorrow" do
      sign_in @user1
      set_beta
      put :add, :location_id => @sbux.id, :expires => 'tomorrow'
      # should add location to planned checkins list
      assert_equal 1, @user1.reload.planned_checkins.count
      assert_equal [@sbux], @user1.reload.planned_checkins.collect(&:location)
      assert_equal [Date.today+1.day], @user1.reload.planned_checkins.collect{ |o| o.expires_at.to_date }
      # should add growl message
      assert_equal 1, assigns(:growls).size
      assert_redirected_to '/'
      assert_equal "We added Starbucks to your todo list", flash[:notice]
    end

    should "create location and add planned checkin" do
      sign_in @user1
      set_beta
      put :add, :location => {:name => "Intelligentsia Coffee",
                              :source => "foursquare:44123",
                              :address => "53 W. Jackson Blvd.",
                              :city_state => "Chicago:IL",
                              :lat => "41.877901218486535",
                              :lng => "-87.62948513031006"}
      # should create location
      assert assigns(:location)
      # should add location to planned checkins list
      assert_equal 1, @user1.reload.planned_checkins.count
      assert_equal ["Intelligentsia Coffee"], @user1.reload.planned_checkins.collect{ |pc| pc.location.name }
      # should add growl message
      assert_equal 1, assigns(:growls).size
      assert_redirected_to '/'
      assert_equal "We added Intelligentsia Coffee to your todo list", flash[:notice]
    end

    should "ignore if location already on planned list" do
      @pcheckin1 = @user1.planned_checkins.create(:location => @sbux)
      sign_in @user1
      set_beta
      put :add, :location_id => @sbux.id
      # should have same planned checkin
      assert_equal [@pcheckin1], @user1.planned_checkins 
      # should not add growl message
      assert_nil assigns(:growls)
      assert_redirected_to '/'
      assert_nil flash[:notice]
    end

    should "allow if location already on checkin list" do
      @user1.locationships.create!(:location => @sbux, :my_checkins => 1)
      sign_in @user1
      set_beta
      put :add, :location_id => @sbux.id
      # should add location to planned checkins list
      assert_equal 1, @user1.reload.planned_checkins.count
      assert_equal [@sbux], @user1.reload.planned_checkins.collect(&:location)
      # should add growl message
      assert_equal 1, assigns(:growls).size
      assert_redirected_to '/'
      assert_equal "We added Starbucks to your todo list", flash[:notice]
    end

    should "redirect to params['return_to]" do
      sign_in @user1
      set_beta
      put :add, :location_id => @sbux.id, :return_to => "/plans"
      assert_redirected_to '/plans'
    end
  end
  
end
