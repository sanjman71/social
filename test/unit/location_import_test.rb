require 'test_helper'

class LocationImportTest < ActiveSupport::TestCase

  def setup
    # create country, state, but not city
    @us = Country.us || Factory(:us)
    @il = Factory(:il, :country => @us)
  end

  context "import foursquare location" do
    should "create location for new location, add location source" do
      @hash     = Hash["id"=>4172889, "name"=>"Zed 451", "address"=>"763 N. Clark St.", "city"=>"Chicago", 
                       "state"=>"Illinois", "geolat"=>41.8964066, "geolong"=>-87.6312161]
      @location = LocationImport.import_foursquare_venue(@hash)
      assert @location.valid?
      # should create city, location
      assert_equal @us, @location.country
      assert_equal @il, @location.state
      assert_equal 'Chicago', @location.city.name
      assert_equal @il, @location.city.state
      assert_equal '763 N Clark St', @location.street_address
      assert_equal 41.8964066, @location.lat
      assert_equal -87.6312161, @location.lng
      # should create location_source for foursquare venue
      assert_equal 1, @location.location_sources.size
      assert_equal ['foursquare'], @location.location_sources.collect(&:source_type)
      assert_equal ['4172889'], @location.location_sources.collect(&:source_id)
      # should find this locaton if we search again
      @location2 = LocationImport.import_foursquare_venue(@hash)
      assert @location2.valid?
      assert_equal @location, @location2
    end
    
    should "create yojimbo" do
      @hash     = Hash['address' => "1310 N Clybourn", 'city' => "Chicago", 'geolat' => 41.905768, 'geolong' => -87.642783,
                       'id' => 2167915, 'name' => "Yojimbo's Garage", 'state' => "IL"]
      @location = LocationImport.import_foursquare_venue(@hash)
      assert @location.valid?
    end
  end

  context "import facebook location" do
    should "create location for new location, add location source" do
      @hash     = Hash["id"=>"117669674925118", "name"=>"Bull & Bear",
                       "location"=>{"street"=>"431 N Wells St", "city"=>"Chicago", "state"=>"IL", "zip"=>"60654-4512",
                                    "latitude"=>41.890177, "longitude"=>-87.633815}]
      @location = LocationImport.import_facebook_place(@hash)
      # should create city, location
      assert_equal @us, @location.country
      assert_equal @il, @location.state
      assert_equal 'Chicago', @location.city.name
      assert_equal @il, @location.city.state
      assert_equal '431 N Wells St', @location.street_address
      assert_equal 41.890177, @location.lat
      assert_equal -87.633815, @location.lng
      # should create location_source for foursquare venue
      assert_equal 1, @location.location_sources.size
      assert_equal ['facebook'], @location.location_sources.collect(&:source_type)
      assert_equal ['117669674925118'], @location.location_sources.collect(&:source_id)
      # should find this locaton if we search again
      @location2 = LocationImport.import_facebook_place(@hash)
      assert @location2.valid?
      assert_equal @location, @location2
    end
  end
end