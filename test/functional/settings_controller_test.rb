require 'test_helper'

class SettingsControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  context "routes" do
    should route(:get, "/settings").to(:controller => 'settings', :action => 'show')
    should route(:put, "/settings").to(:controller => 'settings', :action => 'update')
  end

  def setup
    @us         = Factory(:us)
    @ca         = Factory(:canada)
    @il         = Factory(:il, :country => @us)
    @ny         = Factory(:ny, :country => @us)
    @ma         = Factory(:ma, :country => @us)
    @on         = Factory(:ontario, :country => @ca)
    @chicago    = Factory(:city, :name => 'Chicago', :state => @il, :lat => 41.8781136, :lng => -87.6297982)
    @newyork    = Factory(:city, :name => 'New York', :state => @ny, :lat => 40.7143528, :lng => -74.0059731)
    @boston     = Factory(:city, :name => 'Boston', :state => @ma, :lat => 42.3584308, :lng => -71.0597732)
  end

  context "edit" do
    # should "not allow another user to edit your profile" do
    #   setup_badges
    #   @user1 = Factory.create(:user, :handle => 'user1')
    #   @user2 = Factory.create(:user, :handle => 'user2')
    #   sign_in @user1
    #   set_beta
    #   get :show, :user => {}
    #   assert_redirected_to "/unauthorized"
    # end
  end

  context "update" do
    # should "not allow another user to update your profile" do
    #   setup_badges
    #   @user1 = Factory.create(:user, :handle => 'user1')
    #   @user2 = Factory.create(:user, :handle => 'user2')
    #   sign_in @user1
    #   set_beta
    #   put :update, :id => @user2.id, :user => {}
    #   assert_redirected_to "/unauthorized"
    # end
  
    should "not change user city when id is specified" do
      setup_badges
      @chicago_user = Factory.create(:user, :handle => 'chicago_user', :city => @chicago)
      sign_in @chicago_user
      set_beta
      put :update, :user => {:city_attributes => {:id => @chicago.id, :name => 'Chicago'}}
      # should not change user city
      assert_equal @chicago, @chicago_user.reload.city
    end

    should "not change user city when name is specified" do
      setup_badges
      @chicago_user = Factory.create(:user, :handle => 'chicago_user', :city => @chicago)
      sign_in @chicago_user
      set_beta
      put :update, :user => {:city_attributes => {:name => 'Chicago'}}
      # should not change user city
      assert_equal @chicago, @chicago_user.reload.city
    end

    should "change user city to boston" do
      setup_badges
      @chicago_user = Factory.create(:user, :handle => 'chicago_user', :city => @chicago)
      sign_in @chicago_user
      set_beta
      put :update, :user => {:city_attributes => {:name => 'Boston, MA'}}
      # should change user city
      assert_equal @boston, @chicago_user.reload.city
    end

    should "change user city to toronto" do
      setup_badges
      @chicago_user = Factory.create(:user, :handle => 'chicago_user', :city => @chicago)
      sign_in @chicago_user
      set_beta
      put :update, :user => {:city_attributes => {:name => 'Toronto canada'}}
      # should change user city
      assert_equal 'Toronto', @chicago_user.reload.city.name
    end

    should "change gender to 'male'" do
      setup_badges
      @chicago_user = Factory.create(:user, :handle => 'chicago_user', :gender => 'female')
      assert_equal 1, @chicago_user.gender
      sign_in @chicago_user
      set_beta
      put :update, :user => {:gender => 'male'}
      assert_equal 2, @chicago_user.reload.gender
    end

    should "change orientation to 'gay'" do
      setup_badges
      @chicago_user = Factory.create(:user, :handle => 'chicago_user', :orientation => 'straight')
      assert_equal 3, @chicago_user.orientation
      sign_in @chicago_user
      set_beta
      put :update, :user => {:orientation => 'gay'}
      assert_equal 2, @chicago_user.reload.orientation
    end
  end

end