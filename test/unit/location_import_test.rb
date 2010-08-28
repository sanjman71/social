require 'test_helper'

class LocationImportTest < ActiveSupport::TestCase

  def setup
    @us       = Country.us || Factory(:us)
    @il       = Factory(:il, :country => @us)
    @chicago  = Factory(:chicago, :state => @il, :timezone => Factory(:timezone_chicago))
  end

  context "import foursquare location" do
    should "create location for new location, add location source" do
      @hash     = Hash["id"=>4172889, "name"=>"Zed 451", "address"=>"763 N. Clark St.", "city"=>"Chicago", 
                       "state"=>"Illinois", "geolat"=>41.8964066, "geolong"=>-87.6312161]
      @location = LocationImport.import_foursquare_venue(@hash)
      assert @location.valid?
      # should create location with geo params
      assert_equal @us, @location.country
      assert_equal @il, @location.state
      assert_equal @chicago, @location.city
      assert_equal '763 N Clark St', @location.street_address
      assert_equal 41.8964066, @location.lat
      assert_equal -87.6312161, @location.lng
      # should create location_source for foursquare venue
      assert_equal 1, @location.location_sources.size
      assert_equal ['fs'], @location.location_sources.collect(&:source_type)
      assert_equal [4172889], @location.location_sources.collect(&:source_id)
      # should find this locaton if we search again
      @location2 = LocationImport.import_foursquare_venue(@hash)
      assert @location2.valid?
      assert_equal @location, @location2
    end
  end

end