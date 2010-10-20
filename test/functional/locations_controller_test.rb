require 'test_helper'

class LocationsControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  # turn off transactional fixtures here so we can test sphinx
  self.use_transactional_fixtures = false

  context "routes" do
    should route(:get, "/locations/geo:1.23..-77.89/radius:50").to(
      :controller => 'locations', :action => 'index', :geo => 'geo:1.23..-77.89', :radius => 'radius:50')
    should route(:get, "/locations/city:chicago/radius:50").to(
      :controller => 'locations', :action => 'index', :city => 'city:chicago', :radius => 'radius:50')
    should route(:get, "/locations/city:chicago").to(
      :controller => 'locations', :action => 'index', :city => 'city:chicago')
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
      @user1 = Factory.create(:user, :handle => 'User1', :city => @chicago)
      @user2 = Factory.create(:user, :handle => "User2", :city => @chicago)
      @user3 = Factory.create(:user, :handle => "User3", :city => @boston)
    end

    context "city" do
      should "find city users within default radius" do
        ThinkingSphinx::Test.run do
          ThinkingSphinx::Test.index
          sleep(0.25)
          sign_in @user1
          set_beta
          get :index, :city => 'city:chicago'
          assert_equal @chicago, assigns(:city)
          assert_equal 50, assigns(:radius)
          assert_equal [Math.degrees_to_radians(@chicago.lat), Math.degrees_to_radians(@chicago.lng)], assigns(:options)[:geo_origin]
          assert_equal 0..Math.miles_to_meters(50), assigns(:options)[:geo_distance]
          assert_equal [], assigns(:locations)
          assert_template "index"
        end
      end
    end

    context "geo" do
      should "find geo users within default radius" do
        ThinkingSphinx::Test.run do
          ThinkingSphinx::Test.index
          sleep(0.25)
          sign_in @user1
          set_beta
          get :index, :geo => "geo:#{@chicago.lat}..#{@chicago.lng}"
          assert_equal 41.850033, assigns(:lat)
          assert_equal -87.6500523, assigns(:lng)
          assert_equal 50, assigns(:radius)
          assert_equal [Math.degrees_to_radians(@chicago.lat), Math.degrees_to_radians(@chicago.lng)], assigns(:options)[:geo_origin]
          assert_equal 0..Math.miles_to_meters(50), assigns(:options)[:geo_distance]
          assert_equal [], assigns(:locations)
          assert_template "index"
        end
      end
    end
  end

end