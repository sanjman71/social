require 'test_helper'

class LocationImportTest < ActiveSupport::TestCase

  # turn off transactional fixtures here so we can test sphinx
  self.use_transactional_fixtures = false

  def setup
    ThinkingSphinx::Test.init
    # create country and state, no cities
    @us = Country.us || Factory(:us)
    @il = Factory(:il, :country => @us)
  end

  def teardown
    [Country, State, User, Location, Delayed::Job].each { |o| o.delete_all }
  end

  context "import" do
    should "create city, location, and location source with address, city, state, zip, lat, and lng specified" do
      ThinkingSphinx::Test.run do
        @hash     = Hash["name" => "Bull & Bear", "address"=>"431 N Wells St", "city"=>"Chicago", "state"=>"IL",
                         "zip"=>"60654-4512", "lat"=>41.890177, "lng"=>-87.633815]
        @location = LocationImport.import_location('117669674925118', 'facebook', @hash)
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
        # should find this location if we search again
        @location2 = LocationImport.import_location('117669674925118', 'facebook', @hash)
        assert @location2.valid?
        assert_equal @location, @location2
      end
    end

    should "create location and location source with city, state, lat, lng specified" do
      ThinkingSphinx::Test.run do
        @hash     = Hash["name"=>"Zed 451", "city"=>"Chicago", "state"=>"Illinois",
                         "lat"=>41.8964066, "lng"=>-87.6312161]
        @location = LocationImport.import_location('4172889', 'foursquare', @hash)
        assert @location.valid?
        # should create city, location
        assert_equal "Zed 451", @location.name
        assert_equal @us, @location.country
        assert_equal @il, @location.state
        assert_equal 'Chicago', @location.city.name
        assert_equal @il, @location.city.state
        assert_equal '', @location.street_address
        assert_equal 41.8964066, @location.lat
        assert_equal -87.6312161, @location.lng
        # should create location_source for foursquare venue
        assert_equal 1, @location.location_sources.size
        assert_equal ['foursquare'], @location.location_sources.collect(&:source_type)
        assert_equal ['4172889'], @location.location_sources.collect(&:source_id)
        # should find this locaton if we search again
        @location2 = LocationImport.import_location('4172889', 'foursquare', @hash)
        assert @location2.valid?
        assert_equal @location, @location2
      end
    end
 
    should "create location and location source with lat and lng specified" do
      @hash     = Hash["name"=>"Chicago O'Hare International Airport",
                       "lat"=>41.9794742, "lng"=>-87.9042318]
      @location = LocationImport.import_location("151394801542515", 'facebook', @hash)
      # should create location with lat, lng
      assert_equal "Chicago O'Hare International Airport", @location.name
      assert_equal 41.9794742, @location.lat
      assert_equal -87.9042318, @location.lng
      # should create location_source for foursquare venue
      assert_equal 1, @location.location_sources.size
      assert_equal ['facebook'], @location.location_sources.collect(&:source_type)
      assert_equal ['151394801542515'], @location.location_sources.collect(&:source_id)
    end
  end

  should "import tags after adding a location source" do
    Delayed::Job.delete_all
    # create location, location source
    @location = Location.create(:name => 'Starbucks - State St and Ohio St', :address => '600 N State St',
                                :state => @il, :country => @us)
    # should call location.event_location_tagged after tagging location source
    Location.any_instance.expects(:event_location_tagged).once
    @source   = @location.location_sources.create(:source_id => '108207', :source_type => 'foursquare')
    # should add job to import tags
    assert_equal 1, Delayed::Job.all.select { |dj| dj.handler.match(/async_import_tags/) }.size
    work_off_delayed_jobs(/async_import_tags/)
    # should add location tags
    assert_equal ['coffee shop', 'food'], @location.reload.tag_list
    # should mark location_source tag_count, tagged_at
    assert @source.reload.tagged?
    assert_equal 2, @source.reload.tag_count
    assert @source.reload.tagged_at
  end

end