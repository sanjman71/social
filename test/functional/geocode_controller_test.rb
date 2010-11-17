require 'test_helper'

class GeocodeControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  context "routes" do
    should route(:get, '/geocode/google').to(:controller => 'geocode', :action => 'search', :provider => 'google')
  end

  context "search google" do
    should "geocode chicago to geocoded object" do
      set_beta
      get :search, :provider => 'google', :q => 'chicago', :format => 'json'
      assert_equal "application/json", @response.content_type
      @json = JSON.parse(@response.body)
      assert_equal 'ok', @json['status']
      assert_equal 'Chicago', @json['city']
      assert_equal 'IL', @json['state']
    end

    should "geocode toronto, canada to geocoded object" do
      set_beta
      get :search, :provider => 'google', :q => 'toronto, canada', :format => 'json'
      assert_equal "application/json", @response.content_type
      @json = JSON.parse(@response.body)
      assert_equal 'ok', @json['status']
      assert_equal 'Toronto', @json['city']
      assert_equal 'ON', @json['state']
    end

    should "geocode paris, france to geocoded object" do
      set_beta
      get :search, :provider => 'google', :q => 'paris', :format => 'json'
      assert_equal "application/json", @response.content_type
      @json = JSON.parse(@response.body)
      assert_equal 'ok', @json['status']
      assert_equal 'Paris', @json['city']
      assert_equal 'France', @json['country']
    end
  end

end