require 'test_helper'

class HomeControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  context "routes" do
    should route(:put, '/stream/daters').to(:controller => 'home', :action => 'stream', :name => 'daters')
    should route(:put, '/geo/chicago').to(:controller => 'home', :action => 'geo', :name => 'chicago')
  end

  def setup
    @us       = Factory(:us)
    @il       = Factory(:il, :country => @us)
    @ma       = Factory(:ma, :country => @us)
    @chicago  = Factory(:city, :name => 'Chicago', :state => @il, :lat => 41.850033, :lng => -87.6500523)
    @boston   = Factory(:city, :name => 'Boston', :state => @ma, :lat => 42.3584308, :lng => -71.0597732)
    @user     = Factory(:user, :city => @chicago)
  end

  context "index" do
    should "allow guests" do
      set_beta
      get :index
      assert_template "home/index"
    end

    should "set default stream and geo" do
      set_beta
      sign_in @user
      get :index
      assert assigns(:method)
      assert assigns(:checkins)
      assert_equal 'my', assigns(:stream)
      assert_equal @chicago, assigns(:geo)
      assert_equal 'my', session[:current_stream]
      assert_equal 'chicago', session[:current_geo]
    end

    should "use session[:current_stream]" do
      set_beta
      sign_in @user
      session[:current_stream] = 'friends'
      get :index
      assert assigns(:method)
      assert assigns(:checkins)
      assert_equal 'friends', assigns(:stream)
      assert_equal 'friends', session[:current_stream]
    end

    should "use session[:current_geo]" do
      set_beta
      sign_in @user
      session[:current_geo] = 'boston'
      get :index
      assert assigns(:method)
      assert assigns(:checkins)
      assert_equal @boston, assigns(:geo)
      assert_equal 'boston', session[:current_geo]
    end
  end

  context "stream" do
    should "set session[:current_stream]" do
      set_beta
      sign_in @user
      put :stream, :name => 'my-stream'
      assert_equal 'my-stream', session[:current_stream]
      assert_redirected_to "/"
    end
  end

  context "geo" do
    should "set session[:current_geo]" do
      set_beta
      sign_in @user
      put :geo, :name => 'boston'
      assert_equal 'boston', session[:current_geo]
      assert_redirected_to "/"
    end
  end
end