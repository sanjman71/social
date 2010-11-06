require 'test_helper'

class HomeControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  context "routes" do
    should route(:put, '/stream').to(:controller => 'home', :action => 'stream')
  end

  def setup
    @user = Factory(:user)
  end

  context "index" do
    should "allow guests" do
      set_beta
      get :index
      assert_template "home/index"
    end

    should "use default stream" do
      set_beta
      sign_in @user
      get :index
      assert assigns(:method)
      assert assigns(:checkins)
      assert_equal 'my', assigns(:stream)
    end

    should "use sesssion[:current_stream]" do
      set_beta
      sign_in @user
      session[:current_stream] = 'friends-stream'
      get :index
      assert assigns(:method)
      assert assigns(:checkins)
      assert_equal 'friends', assigns(:stream)
    end
  end

  context "stream" do
    should "set session[:current_stream]" do
      set_beta
      sign_in @user
      put :stream, :name => 'my-stream'
      assert_redirected_to "/"
      assert_equal 'my-stream', session[:current_stream]
    end
  end
  
end