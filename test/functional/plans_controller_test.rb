require 'test_helper'

class PlansControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  context "routes" do
    should route(:put, 'plans/add').to(:controller => 'plans', :action => 'add')
    should route(:put, 'plans/add/1').to(:controller => 'plans', :action => 'add', :location_id => '1')
    should route(:put, 'plans/join/1').to(:controller => 'plans', :action => 'join', :plan_id => '1')
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

  context "join" do
    setup do
      @user1    = Factory.create(:user, :handle => 'User1', :city => @chicago)
      @user2    = Factory.create(:user, :handle => 'User2', :city => @chicago)
      @going_at = Time.zone.now.end_of_day + 1.day
      @todo1    = @user1.planned_checkins.create!(:location => @sbux, :going_at => @going_at)
    end

    should "add planned checkin and send email to original planner" do
      sign_in @user2
      set_beta
      put :join, :plan_id => @todo1.id, :going => 'tomorrow'
      # should add location to planned checkins list, with original going_at
      assert_equal 1, @user1.reload.planned_checkins.count
      assert_equal [@sbux], @user1.reload.planned_checkins.collect(&:location)
      assert_equal [@going_at.to_i], @user1.reload.planned_checkins.collect{ |o| o.going_at.to_i }
      # should add growl message
      assert_equal 1, assigns(:growls).size
      # should redirect and set flash
      assert_redirected_to '/'
      assert_equal "We added Starbucks to your todo list", flash[:notice]
    end
  end

  context "add" do
    setup do
      @user1 = Factory.create(:user, :handle => 'User1', :city => @chicago)
    end

    should "add planned checkin with default going_at" do
      sign_in @user1
      set_beta
      put :add, :location_id => @sbux.id
      # should add location to planned checkins list, with default going_at
      assert_equal 1, @user1.reload.planned_checkins.count
      assert_equal [@sbux], @user1.reload.planned_checkins.collect(&:location)
      assert_equal [nil], @user1.reload.planned_checkins.collect{ |o| o.going_at }
      # should add growl message
      assert_equal 1, assigns(:growls).size
      assert_redirected_to '/'
      assert_equal "We added Starbucks to your todo list", flash[:notice]
    end

    should "add planned checkin with going_at tomorrow" do
      sign_in @user1
      set_beta
      put :add, :location_id => @sbux.id, :going => 'tomorrow'
      # should add location to planned checkins list
      assert_equal 1, @user1.reload.planned_checkins.count
      assert_equal [@sbux], @user1.reload.planned_checkins.collect(&:location)
      assert_equal [Date.today+1.day], @user1.reload.planned_checkins.collect{ |o| o.going_at.to_date }
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
