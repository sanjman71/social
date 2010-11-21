require 'test_helper'

class LocationsControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  # turn off transactional fixtures here so we can test sphinx
  self.use_transactional_fixtures = false

  context "routes" do
    should route(:get, "/locations/geo:1.23..-77.89/radius:50").
      to(:controller => 'locations', :action => 'index', :geo => 'geo:1.23..-77.89', :radius => 'radius:50')
    should route(:get, "/locations/city:chicago/radius:50").
      to(:controller => 'locations', :action => 'index', :city => 'city:chicago', :radius => 'radius:50')
    should route(:get, "/locations/city:chicago").
      to(:controller => 'locations', :action => 'index', :city => 'city:chicago')
    should route(:get, '/locations/geocode/google').
      to(:controller => 'locations', :action => 'geocode', :provider => 'google')
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
          # ThinkingSphinx::Test.index
          # sleep(0.25)
          sign_in @user1
          set_beta
          get :index, :city => 'city:chicago'
          assert_equal @chicago, assigns(:city)
          assert_equal 50, assigns(:radius)
          assert_equal [@chicago.lat.radians, @chicago.lng.radians], assigns(:options)[:geo_origin]
          assert_equal 0..50.miles.meters.value, assigns(:options)[:geo_distance]
          assert_equal [], assigns(:locations)
          assert_template "index"
        end
      end
    end

    context "geo" do
      should "find geo users within default radius" do
        ThinkingSphinx::Test.run do
          # ThinkingSphinx::Test.index
          # sleep(0.25)
          sign_in @user1
          set_beta
          get :index, :geo => "geo:#{@chicago.lat}..#{@chicago.lng}"
          assert_equal 41.850033, assigns(:lat)
          assert_equal -87.6500523, assigns(:lng)
          assert_equal 50, assigns(:radius)
          assert_equal [@chicago.lat.radians, @chicago.lng.radians], assigns(:options)[:geo_origin]
          assert_equal 0..50.miles.meters.value, assigns(:options)[:geo_distance]
          assert_equal [], assigns(:locations)
          assert_template "index"
        end
      end
    end
  end

  context "geocode google" do
    setup do
      @user1 = Factory.create(:user, :handle => 'User1', :city => @chicago)
    end

    should "geocode chicago street to geocoded object" do
      set_beta
      sign_in @user1
      get :geocode, :provider => 'google', :q => '900 n michigan chicgo', :format => 'json'
      assert_equal "application/json", @response.content_type
      @json = JSON.parse(@response.body)
      assert_equal 'ok', @json['status']
      assert_equal 1, @json['count']
      assert_equal '900 N Michigan Ave', @json['locations'][0]['street_address']
      assert_equal 'Chicago', @json['locations'][0]['city']
      assert_equal 'IL', @json['locations'][0]['state']
    end

    should "geocode chicago to geocoded object" do
      set_beta
      sign_in @user1
      get :geocode, :provider => 'google', :q => 'chicago', :format => 'json'
      assert_equal "application/json", @response.content_type
      @json = JSON.parse(@response.body)
      assert_equal 'ok', @json['status']
      assert_equal 1, @json['count']
      assert_equal 'Chicago', @json['locations'][0]['city']
      assert_equal 'IL', @json['locations'][0]['state']
    end

    should "geocode toronto, canada to geocoded object" do
      set_beta
      sign_in @user1
      get :geocode, :provider => 'google', :q => 'toronto, canada', :format => 'json'
      assert_equal "application/json", @response.content_type
      @json = JSON.parse(@response.body)
      assert_equal 'ok', @json['status']
      assert_equal 1, @json['count']
      assert_equal 'Toronto', @json['locations'][0]['city']
      assert_equal 'ON', @json['locations'][0]['state']
    end

    should "geocode paris, france to geocoded object" do
      set_beta
      sign_in @user1
      get :geocode, :provider => 'google', :q => 'paris', :format => 'json'
      assert_equal "application/json", @response.content_type
      @json = JSON.parse(@response.body)
      assert_equal 'ok', @json['status']
      assert_equal 1, @json['count']
      assert_equal 'Paris', @json['locations'][0]['city']
      assert_equal 'France', @json['locations'][0]['country']
    end
  end

end