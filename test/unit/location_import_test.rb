require 'test_helper'

class LocationImportTest < ActiveSupport::TestCase

  # turn off transactional fixtures here so we can test sphinx
  self.use_transactional_fixtures = false

  def setup
    ThinkingSphinx::Test.init
    # create country and state, but not city
    @us = Country.us || Factory(:us)
    @il = Factory(:il, :country => @us)
  end

  def teardown
    Country.delete_all
    State.delete_all
    User.delete_all
    Location.delete_all
    Delayed::Job.delete_all
  end

  context "import foursquare location" do
    should "create location for new location, add location source" do
      ThinkingSphinx::Test.run do
        @hash     = Hash["id"=>4172889, "name"=>"Zed 451", "address"=>"763 N. Clark St.", "city"=>"Chicago", 
                         "state"=>"Illinois", "geolat"=>41.8964066, "geolong"=>-87.6312161]
        @location = LocationImport.import_foursquare_venue(@hash)
        assert @location.valid?
        # should create city, location
        assert_equal "Zed 451", @location.name
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
    end
    
    should "create yojimbo" do
      ThinkingSphinx::Test.run do
        @hash     = Hash['address' => "1310 N Clybourn", 'city' => "Chicago", 'geolat' => 41.905768, 'geolong' => -87.642783,
                         'id' => 2167915, 'name' => "Yojimbo's Garage", 'state' => "IL"]
        @location = LocationImport.import_foursquare_venue(@hash)
        assert @location.valid?
      end
    end
  end

  context "import facebook location" do
    should "create location with street, city, state, zip, lat, and lng" do
      ThinkingSphinx::Test.run do
        @hash     = Hash["id"=>"117669674925118", "name"=>"Bull & Bear",
                         "location"=>{"street"=>"431 N Wells St", "city"=>"Chicago", "state"=>"IL", "zip"=>"60654-4512",
                                      "latitude"=>41.890177, "longitude"=>-87.633815}]
        @location = LocationImport.import_facebook_place(@hash)
        # should create city, location
        assert_equal "Bull & Bear", @location.name
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

    should "create location with lat and lng" do
      @hash     = Hash["id"=>"151394801542515", "name"=>"Chicago O'Hare International Airport",
                       "location"=>{"latitude"=>41.9794742, "longitude"=>-87.9042318}]
      @location = LocationImport.import_facebook_place(@hash)
      # should create location with lat, lng
      assert_equal "Chicago O'Hare International Airport", @location.name
      assert_equal 41.9794742, @location.lat
      assert_equal -87.9042318, @location.lng
    end
  end

  context "foursquare location tags" do
    should "import tags after adding a location source" do
      Delayed::Job.delete_all
      # create location, location source
      @location = Location.create(:name => 'Starbucks - State St and Ohio St', :address => '600 N State St',
                                  :state => @il, :country => @us)
      # should call location.after_tagging after tagging location source
      Location.any_instance.expects(:after_tagging).once
      @source   = @location.location_sources.create(:source_id => '108207', :source_type => 'foursquare')
      # should add dj to import tags
      assert_equal 1, Delayed::Job.all.select { |dj| dj.handler.match(/import_tags/) }.size
      Delayed::Worker.new.work_off(1)
      # should add location tags
      assert_equal ['cafe', 'food'], @location.reload.tag_list
      # should mark location_source tag_count, tagged_at
      assert @source.reload.tagged?
      assert_equal 2, @source.reload.tag_count
      assert @source.reload.tagged_at
    end
  end
end