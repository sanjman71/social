require 'test_helper'

class CheckinsControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  context "routes" do
    should route(:get, '/users/1/checkins').to(:controller => 'checkins', :action => 'index', :user_id => '1')
    should route(:get, '/users/1/checkins/friends').
      to(:controller => 'checkins', :action => 'index', :search => 'friends', :user_id => '1')
    should route(:get, "/users/1/checkins/geo:1.23..-77.89/radius:50").
      to(:controller => 'checkins', :action => 'index', :geo => 'geo:1.23..-77.89', :radius => 'radius:50',
         :user_id => '1')
    should route(:get, "/users/1/checkins/city:chicago/radius:50").
      to(:controller => 'checkins', :action => 'index', :city => 'city:chicago', :radius => 'radius:50',
         :user_id => '1')
    should route(:get, "/users/1/checkins/geo:1.23..-77.89/radius:50/all").
      to(:controller => 'checkins', :action => 'index', :geo => 'geo:1.23..-77.89', :radius => 'radius:50',
         :search => 'all', :user_id => '1')
  end

  def setup
    @us         = Factory(:us)
    @il         = Factory(:il, :country => @us)
    @ny         = Factory(:ny, :country => @us)
    @ma         = Factory(:ma, :country => @us)
    @chicago    = Factory(:city, :name => 'Chicago', :state => @il, :lat => 41.8781136, :lng => -87.6297982)
    @newyork    = Factory(:city, :name => 'New York', :state => @ny, :lat => 40.7143528, :lng => -74.0059731)
    @boston     = Factory(:city, :name => 'Boston', :state => @ma, :lat => 42.3584308, :lng => -71.0597732)
    # users
    @chicago1   = Factory.create(:user, :handle => 'chicago1', :city => @chicago)
  end

  context "index" do
    should "search all checkins anywher" do
      sign_in @chicago1
      set_beta
      get :index, :user_id => @chicago1.id, :search => 'all'
      assert_equal 'all', assigns(:search)
      assert_equal 'search_all_checkins', assigns(:method)
      assert_equal @chicago1, assigns(:user)
      assert_select "#checkin_title", :text => 'All Checkins, Anywhere', :count => 1
    end

    should "search all checkins within city" do
      sign_in @chicago1
      set_beta
      get :index, :user_id => @chicago1.id, :city => "city:chicago", :radius => "radius:50", :search => 'all'
      assert_equal 'all', assigns(:search)
      assert_equal 'search_all_checkins', assigns(:method)
      assert_equal @chicago1, assigns(:user)
      assert_select "#checkin_title", :text => 'All Checkins, 50 miles around Chicago', :count => 1
    end

    should "search dater checkins within city" do
      sign_in @chicago1
      set_beta
      get :index, :user_id => @chicago1.id, :city => "city:chicago", :radius => "radius:50", :search => 'daters'
      assert_equal 'daters', assigns(:search)
      assert_equal 'search_daters_checkins', assigns(:method)
      assert_equal @chicago1, assigns(:user)
      assert_select "#checkin_title", :text => 'Daters Checkins, 50 miles around Chicago', :count => 1
    end
    
    should "search my checkins" do
      sign_in @chicago1
      set_beta
      get :index, :user_id => @chicago1.id, :city => "city:chicago", :radius => "radius:50", :search => 'my'
      assert_equal 'my', assigns(:search)
      assert_equal 'search_my_checkins', assigns(:method)
      assert_equal @chicago1, assigns(:user)
      assert_select "#checkin_title", :text => 'My Checkins, 50 miles around Chicago', :count => 1
    end
    
    should "search other checkins" do
      sign_in @chicago1
      set_beta
      get :index, :user_id => @chicago1.id, :city => "city:chicago", :radius => "radius:50", :search => 'others'
      assert_equal 'others', assigns(:search)
      assert_equal 'search_others_checkins', assigns(:method)
      assert_equal @chicago1, assigns(:user)
    end
    
    should "search friend checkins" do
      sign_in @chicago1
      set_beta
      get :index, :user_id => @chicago1.id, :city => "city:chicago", :radius => "radius:50", :search => 'friends'
      assert_equal 'friends', assigns(:search)
      assert_equal 'search_friends_checkins', assigns(:method)
      assert_equal @chicago1, assigns(:user)
    end
  end
end
