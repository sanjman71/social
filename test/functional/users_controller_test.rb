require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  # turn off transactional fixtures here so we can test sphinx
  self.use_transactional_fixtures = false

  context "routes" do
    should route(:get, "/users/geo:1.23..-77.89/radius:50").to(
      :controller => 'users', :action => 'index', :geo => 'geo:1.23..-77.89', :radius => 'radius:50')
    should route(:get, "/users/city:chicago/radius:75").to(
      :controller => 'users', :action => 'index', :city => 'city:chicago', :radius => 'radius:75')
    should route(:get, "/users/city:chicago").to(
      :controller => 'users', :action => 'index', :city => 'city:chicago')
  end

  def setup
    ThinkingSphinx::Test.init
    cleanup
    @us         = Factory(:us)
    @il         = Factory(:il, :country => @us)
    @ny         = Factory(:ny, :country => @us)
    @ma         = Factory(:ma, :country => @us)
    @chicago    = Factory(:city, :name => 'Chicago', :state => @il, :lat => 41.850033, :lng => -87.6500523)
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
      should "find 2 users within 5 mile radius of lat, lng" do
        # change 60610 city to zip later
        @z60610   = Factory(:city, :name => "60610", :state => @il, :lat => 41.9028369, :lng => -87.6359125)
        @chicago3 = Factory.create(:user, :handle => "chicago3", :city => @z60610)
        ThinkingSphinx::Test.run do
          ThinkingSphinx::Test.index
          sleep(0.25)
          sign_in @chicago1
          set_beta
          get :index, :geo => "geo:#{@chicago.lat}..#{@chicago.lng}", :radius => "radius:5"
          assert_equal 41.850033, assigns(:lat)
          assert_equal -87.6500523, assigns(:lng)
          assert_equal 5, assigns(:radius)
          assert_equal [@chicago.lat.radians, @chicago.lng.radians], assigns(:options)[:geo_origin]
          assert_equal 0.0..5.miles.meters.value, assigns(:options)[:geo_distance]
          assert_equal [@chicago2, @chicago3], assigns(:users)
          assert_template "index"
        end
      end
    end
  end
  
  context "show" do
    setup do
      # create user with tag badge
      @user1      = Factory.create(:user, :handle => 'User1', :city => @chicago)
      @voter      = Factory.create(:user, :handle => "Voter", :city => @chicago)
      @tag_badge  = TagBadge.create!(:name => "Shopaholic", :regex => "shopping")
      @badging    = @user1.tag_badges.push(@tag_badge)
    end

    context "badge voting" do
      should "show agree/disagree if user has not voted yet" do
        ThinkingSphinx::Test.run do
          ThinkingSphinx::Test.index
          sleep(0.25)
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
        # add tag badge vote
        @user1.tag_badging_votes.create!(:tag_badge => @tag_badge, :voter => @voter, :vote => 1)
        ThinkingSphinx::Test.run do
          ThinkingSphinx::Test.index
          sleep(0.25)
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
end