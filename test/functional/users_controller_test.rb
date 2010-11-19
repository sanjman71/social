require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  # turn off transactional fixtures here so we can test sphinx
  self.use_transactional_fixtures = false

  context "routes" do
    should route(:get, "/users/geo:1.23..-77.89/radius:50").
      to(:controller => 'users', :action => 'index', :geo => 'geo:1.23..-77.89', :radius => 'radius:50')
    should route(:get, "/users/city:chicago/radius:75").
      to(:controller => 'users', :action => 'index', :city => 'city:chicago', :radius => 'radius:75')
    should route(:get, "/users/city:chicago").
      to(:controller => 'users', :action => 'index', :city => 'city:chicago')
    should route(:get, "/users/1/sudo").
      to(:controller => 'users', :action => 'sudo', :id => '1')
  end

  def setup
    ThinkingSphinx::Test.init
    cleanup
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

  def teardown
    cleanup
  end

  def cleanup
    [Country, State, City, Location, User].each { |klass| klass.delete_all }
  end

  context "index" do
    setup do
      @chicago1 = Factory.create(:user, :handle => 'chicago1', :city => @chicago)
      @chicago2 = Factory.create(:user, :handle => "chicago2", :city => @chicago)
      @boston1  = Factory.create(:user, :handle => "boston1", :city => @boston)
    end

    context "city" do
      should "find 1 user within default radius of city" do
        ThinkingSphinx::Test.run do
          ThinkingSphinx::Test.index
          sleep(0.25)
          sign_in @chicago1
          set_beta
          get :index, :city => 'city:chicago'
          assert_equal @chicago, assigns(:city)
          assert_equal 50, assigns(:radius)
          assert_equal [@chicago.lat.radians, @chicago.lng.radians], assigns(:options)[:geo_origin]
          assert_equal 0.0..50.miles.meters.value, assigns(:options)[:geo_distance]
          assert_equal [@chicago2], assigns(:users)
          assert_template "index"
        end
      end
    end

    context "geo" do
      should "find 2 users within 2 mile radius of lat, lng" do
        # 60610 is ~ 1.7 miles from chicago; change city to zip later
        @z60610   = Factory(:city, :name => "60610", :state => @il, :lat => 41.9028369, :lng => -87.6359125)
        @chicago3 = Factory.create(:user, :handle => "chicago3", :city => @z60610)
        # 60613 is ~ 5.4 miles from chicago; change city to zip later
        @z60613   = Factory(:city, :name => "60613", :state => @il, :lat => 41.9529209, :lng => -87.6605791)
        @chicago4 = Factory.create(:user, :handle => "chicago4", :city => @z60613)
        ThinkingSphinx::Test.run do
          sign_in @chicago1
          set_beta
          get :index, :geo => "geo:#{@chicago.lat}..#{@chicago.lng}", :radius => "radius:2"
          assert_equal @chicago.lat, assigns(:lat)
          assert_equal @chicago.lng, assigns(:lng)
          assert_equal 2, assigns(:radius)
          assert_equal [@chicago.lat.radians, @chicago.lng.radians], assigns(:options)[:geo_origin]
          assert_equal 0.0..2.miles.meters.value, assigns(:options)[:geo_distance]
          assert_equal [@chicago2, @chicago3], assigns(:users)
          assert_template "index"
        end
      end
    end
  end
  
  context "show" do
    setup do
      # create user with a badge
      @user1    = Factory.create(:user, :handle => 'User1', :city => @chicago)
      @voter    = Factory.create(:user, :handle => "Voter", :city => @chicago)
      @badge    = Badge.create!(:name => "Shopaholic", :regex => "shopping")
      @badging  = @user1.badges.push(@badge)
    end

    context "points for viewing profile" do
      should "cost 10 points to see another user's profile" do
        @voter.update_attribute(:points, 100)
        sign_in @voter
        set_beta
        get :show, :id => @user1.id
        # should change voter's points
        assert_equal 90, @voter.reload.points
        # should add flash message
        assert_equal 1, flash[:growls].size
      end
      
      should "not cost anything to see my own profile" do
        @voter.update_attribute(:points, 100)
        sign_in @voter
        set_beta
        get :show, :id => @voter.id
        # should not change voter's points
        assert_equal 100, @voter.reload.points
        # should not add flash message
        assert_nil flash[:growls]
      end
    end

    context "profile matches" do
      should "not show matches when viewing somebody else's profile" do
        sign_in @voter
        set_beta
        get :show, :id => @user1.id
        assert_select "div#user_profile_matches_title", 0
        assert_select "div#user_profile_matches", 0
      end

      # should "show matches when viewing your own profile" do
      #   sign_in @user1
      #   set_beta
      #   get :show, :id => @user1.id
      #   assert_select "div#user_profile_matches_title", 1
      #   assert_select "div#user_profile_matches", 1
      # end
    end

    context "badge voting" do
      should "show agree/disagree if user has not voted yet" do
        ThinkingSphinx::Test.run do
          sign_in @voter
          set_beta
          get :show, :id => @user1.id
          assert_template 'show'
          assert_select "span#badge_name", :text => 'Shopaholic'
          assert_select "span#badge_votes", 1
          assert_select "span#agree_disagree", 1
        end
      end

      should "not show agree/disagree if user has already voted" do
        # add badging vote
        @user1.badging_votes.create!(:badge => @badge, :voter => @voter, :vote => 1)
        ThinkingSphinx::Test.run do
          sign_in @voter
          set_beta
          get :show, :id => @user1.id
          assert_template 'show'
          assert_select "span#badge_name", :text => 'Shopaholic'
          assert_select "span#badge_votes", 1
          assert_select "span#agree_disagree", 0
        end
      end
    end
  end

  context "update" do
    should "not change user city when id is specified" do
      @chicago_user = Factory.create(:user, :handle => 'chicago_user', :city => @chicago)
      sign_in @chicago_user
      set_beta
      put :update, :id => @chicago_user.id, :user => {:city_attributes => {:id => @chicago.id, :name => 'Chicago'}}
      # should not change user city
      assert_equal @chicago, @chicago_user.reload.city
    end

    should "not change user city when name is specified" do
      @chicago_user = Factory.create(:user, :handle => 'chicago_user', :city => @chicago)
      sign_in @chicago_user
      set_beta
      put :update, :id => @chicago_user.id, :user => {:city_attributes => {:name => 'Chicago'}}
      # should not change user city
      assert_equal @chicago, @chicago_user.reload.city
    end

    should "change user city to boston" do
      @chicago_user = Factory.create(:user, :handle => 'chicago_user', :city => @chicago)
      sign_in @chicago_user
      set_beta
      put :update, :id => @chicago_user.id, :user => {:city_attributes => {:name => 'Boston, MA'}}
      # should change user city
      assert_equal @boston, @chicago_user.reload.city
    end

    should "change user city to toronto" do
      @chicago_user = Factory.create(:user, :handle => 'chicago_user', :city => @chicago)
      sign_in @chicago_user
      set_beta
      put :update, :id => @chicago_user.id, :user => {:city_attributes => {:name => 'Toronto canada'}}
      # should change user city
      assert_equal 'Toronto', @chicago_user.reload.city.name
    end
  end
end