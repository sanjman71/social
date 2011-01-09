require 'test_helper'

class HomeControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  context "routes" do
    should route(:put, '/stream/daters').to(:controller => 'home', :action => 'stream', :name => 'daters')
    should route(:put, '/city/chicago').to(:controller => 'home', :action => 'city', :name => 'chicago')
    should route(:get, '/about').to(:controller => 'home', :action => 'about')
    should route(:get, '/about:dialog').to(:controller => 'home', :action => 'about', :dialog => ":dialog")
  end

  def setup
    @us       = Factory(:us)
    @il       = Factory(:il, :country => @us)
    @ma       = Factory(:ma, :country => @us)
    @chicago  = Factory(:city, :name => 'Chicago', :state => @il, :lat => 41.850033, :lng => -87.6500523)
    @boston   = Factory(:city, :name => 'Boston', :state => @ma, :lat => 42.3584308, :lng => -71.0597732)
    @user     = Factory(:user, :city => @chicago)
  end

  context "get index" do
    should "redirect guests without beta password to beta#show" do
      get :index
      assert_redirected_to "/beta"
    end

    should "redirect guests with beta password to login" do
      set_beta
      get :index
      assert_redirected_to "/login"
    end

    should "redirect invited users to login" do
      @invitation = @user.invitations.create!(:recipient_email => 'invitee@outlately.com')
      get :index, :token => @invitation.reload.token
      assert_redirected_to "/login"
    end

    context "current_stream" do
      should "set default stream to 'everyone'" do
        set_beta
        sign_in @user
        get :index
        assert_equal 'everyone', assigns(:stream)
        assert_equal 'everyone', session[:current_stream]
      end
      
      should "use stream from session value" do
        set_beta
        sign_in @user
        session[:current_stream] = 'friends'
        get :index
        assert_equal 'friends', assigns(:stream)
        assert_equal 'friends', session[:current_stream]
      end
    end

    context "current_city" do
      should "set default city to user city" do
        set_beta
        sign_in @user
        get :index
        assert_equal @chicago, assigns(:city)
        assert_equal 'chicago', session[:current_city]
      end
      
      should "use city from session value" do
        set_beta
        sign_in @user
        session[:current_city] = 'boston'
        get :index
        assert_equal @boston, assigns(:city)
        assert_equal 'boston', session[:current_city]
      end
    end
  end

  context "put stream" do
    should "set session[:current_stream]" do
      set_beta
      sign_in @user
      put :stream, :name => 'my-stream'
      assert_equal 'my-stream', session[:current_stream]
      assert_redirected_to "/"
    end
  end

  context "put city" do
    should "set session[:current_city]" do
      set_beta
      sign_in @user
      put :city, :name => 'boston'
      assert_equal 'boston', session[:current_city]
      assert_redirected_to "/"
    end
  end
end