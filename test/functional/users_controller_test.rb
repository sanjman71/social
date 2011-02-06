require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  # turn off transactional fixtures here so we can test sphinx
  self.use_transactional_fixtures = false

  context "routes" do
    should route(:get, "/profile").to(:controller => 'users', :action => 'show')
    should route(:get, "/users/geo:1.23..-77.89/radius:50").
      to(:controller => 'users', :action => 'search', :geo => 'geo:1.23..-77.89', :radius => 'radius:50')
    should route(:get, "/users/city:chicago/radius:75").
      to(:controller => 'users', :action => 'search', :city => 'city:chicago', :radius => 'radius:75')
    should route(:get, "/users/city:chicago").
      to(:controller => 'users', :action => 'search', :city => 'city:chicago')
    should route(:get, "/users/1/become").
      to(:controller => 'users', :action => 'become', :id => '1')
    should route(:put, "/users/1/bucks/100").
      to(:controller => 'users', :action => 'bucks', :id => '1', :points => 100)
    should route(:put, "/users/1/activate").
      to(:controller => 'users', :action => 'activate', :id => '1')
    should route(:put, "/users/1/disable").
      to(:controller => 'users', :action => 'disable', :id => '1')
  end

  def setup
    ThinkingSphinx::Test.init
    @il         = states(:il)
    @chicago    = cities(:chicago)
    # use these coordinates for distance calcs below
    @chicago.update_attributes(:lat => 41.8781136, :lng => -87.6297982)
    @newyork    = cities(:new_york)
    @boston     = cities(:boston)
  end

  def teardown
    cleanup
  end

  def cleanup
    DatabaseCleaner.clean
  end

  context "search" do
    setup do
      @chicago1 = Factory.create(:user, :handle => 'chicago1', :city => @chicago)
      @chicago2 = Factory.create(:user, :handle => "chicago2", :city => @chicago)
      @boston1  = Factory.create(:user, :handle => "boston1", :city => @boston)
    end

    context "city" do
      should "find 1 user within default radius of city" do
        ThinkingSphinx::Test.run do
          sleep(0.25)
          sign_in @chicago1
          set_beta
          get :search, :city => 'city:chicago'
          assert_equal @chicago, assigns(:city)
          assert_equal 50, assigns(:radius)
          assert_equal [@chicago.lat.radians, @chicago.lng.radians], assigns(:options)[:geo_origin]
          assert_equal 0.0..50.miles.meters.value, assigns(:options)[:geo_distance]
          assert_equal [@chicago2], assigns(:users)
          assert_template "search"
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
          get :search, :geo => "geo:#{@chicago.lat}..#{@chicago.lng}", :radius => "radius:2"
          assert_equal @chicago.lat, assigns(:lat)
          assert_equal @chicago.lng, assigns(:lng)
          assert_equal 2, assigns(:radius)
          assert_equal [@chicago.lat.radians, @chicago.lng.radians], assigns(:options)[:geo_origin]
          assert_equal 0.0..2.miles.meters.value, assigns(:options)[:geo_distance]
          assert_equal [@chicago2, @chicago3], assigns(:users)
          assert_template "search"
        end
      end
    end
  end
  
  context "show" do
    setup do
      # create user with a badge
      @user1    = Factory.create(:user, :handle => 'User1', :city => @chicago)
      @voter    = Factory.create(:user, :handle => "Voter", :city => @chicago)
      @badge    = Badge.create!(:name => "Shopaholic", :regex => "shopping", :tagline => "Shopping")
      @badging  = @user1.badges.push(@badge)
    end

    # context "edit user link" do
    #   should "show edit link when viewing my profile" do
    #     sign_in @user1
    #     set_beta
    #     get :show, :id => @user1.id
    #     assert_select "#edit_user_link", 1
    #   end
    #   
    #   should "not show edit link when viewing another user's profile" do
    #     sign_in @voter
    #     set_beta
    #     get :show, :id => @user1.id
    #     assert_select "#edit_user_link", 0
    #   end
    # end

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

    # deprecated for now
    # context "badge voting" do
    #   should "show agree/disagree if user has not voted yet" do
    #     ThinkingSphinx::Test.run do
    #       sign_in @voter
    #       set_beta
    #       get :show, :id => @user1.id
    #       assert_template 'show'
    #       assert_select "span#badge_name", :text => 'Shopaholic'
    #       assert_select "span#badge_votes", 1
    #       assert_select "span#agree_disagree", 1
    #     end
    #   end
    # 
    #   should "not show agree/disagree if user has already voted" do
    #     # add badging vote
    #     @user1.badging_votes.create!(:badge => @badge, :voter => @voter, :vote => 1)
    #     ThinkingSphinx::Test.run do
    #       sign_in @voter
    #       set_beta
    #       get :show, :id => @user1.id
    #       assert_template 'show'
    #       assert_select "span#badge_name", :text => 'Shopaholic'
    #       assert_select "span#badge_votes", 1
    #       assert_select "span#agree_disagree", 0
    #     end
    #   end
    # end
  end

  context "disable" do
    setup do
      @admin = Factory.create(:user, :handle => 'admin')
      @admin.grant_role('admin')
      @user1 = Factory.create(:user, :handle => 'user')
      assert @user1.active?
    end

    should "change to disabled state" do
      sign_in @admin
      put :disable, :id => @user1.id, :return_to => "/"
      assert @user1.reload.disabled?
    end
  end

  context "activate" do
    setup do
      @admin = Factory.create(:user, :handle => 'admin')
      @admin.grant_role('admin')
      @user1 = Factory.create(:user, :handle => 'user')
      @user1.disable!
      assert @user1.disabled?
    end

    should "change to active state" do
      sign_in @admin
      put :activate, :id => @user1.id, :return_to => "/"
      assert @user1.reload.active?
    end
  end

  context "learn" do
    setup do
      redis_flushdb
      @user1 = Factory.create(:user, :handle => 'user1')
      assert @user1.active?
      @user2 = Factory.create(:user, :handle => 'user2')
      assert @user2.active?
    end

    context "html request" do
      should "add user2 to user1's learn set" do
        sign_in @user1
        put :learn, :id => @user2.id
        assert_equal ["user:#{@user2.id}"], @user1.learns_get
      end
    end

    context "json request" do
      should "add user2 to user1's learn set" do
        sign_in @user1
        put :learn, :id => @user2.id, :format => 'json'
        assert_equal "application/json", @response.content_type
        @json = JSON.parse(@response.body)
        assert_equal 'ok', @json['status']
        assert @json['added']
        assert_equal ["user:#{@user2.id}"], @user1.learns_get
      end

      should "not re-add user2 to user1's learn set" do
        sign_in @user1
        @user1.learns_add(@user2)
        put :learn, :id => @user2.id, :format => 'json'
        assert_equal "application/json", @response.content_type
        @json = JSON.parse(@response.body)
        assert_equal 'ok', @json['status']
        assert_false @json['added']
        assert_equal ["user:#{@user2.id}"], @user1.learns_get
      end
    end
  end

end