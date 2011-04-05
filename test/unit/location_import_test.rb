require 'test_helper'

class LocationImportTest < ActiveSupport::TestCase
  # turn off transactional fixtures here so we can test sphinx
  self.use_transactional_fixtures = false

  def setup
    # create country and state, no cities
    @us = countries(:us)
    @il = states(:il)
  end

  def teardown
    DatabaseCleaner.clean
  end

  context "import" do
    should "create city, location, and location source with address, city, state, zip, lat, and lng specified" do
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

    should "create location and location source with city, state, lat, lng specified" do
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

  should "import tags asynchronously after adding a location source" do
    # create user oauth token
    @user     = Factory(:user)
    @oauth    = @user.oauths.create(:provider => 'foursquare', :access_token => '12345')
    # stubbed venue details response
    @response =
    {"meta" => {"code" => 200},
     "response" => {"venue" =>
       {"id"=>"4a9d9614f964a520953820e3", "name"=>"Starbucks",
         "contact"=>{"phone"=>"3125730033", "twitter"=>"Starbucks"},
         "location"=>
          {"address"=>"600 N State St", "crossStreet"=>"State St and Ohio St", "city"=>"Chicago",
           "state"=>"IL", "postalCode"=>"60654", "country"=>"USA", "lat"=>41.8927539, "lng"=>-87.6286206},
         "categories"=>
           [
           {"id"=>"4bf58dd8d48988d1e0931735", "name"=>"Coffee Shops", "icon"=>"http://foursquare.com/img/categories/food/coffeeshop.png", "parents"=>["Food"], "primary"=>true},
           {"id"=>"4bf58dd8d48988d16d941735", "name"=>"Cafes", "icon"=>"http://foursquare.com/img/categories/food/cafe.png", "parents"=>["Food"]},
           {"id"=>"4bf58dd8d48988d130941735", "name"=>"Buildings", "icon"=>"http://foursquare.com/img/categories/building/default.png", "parents"=>["Homes, Work, Others"]}
           ],
           "verified"=>true,
           "stats"=>
            {"checkinsCount"=>1814, "usersCount"=>694},
            "hereNow"=>{"count"=>0, "groups"=>[{"type"=>"friends", "name"=>"friends here", "count"=>0, "items"=>[]},
            {"type"=>"others", "name"=>"other people here", "count"=>0, "items"=>[]}]}
        }
      }
    }
    Resque.reset!
    # create location and location source
    @location = Location.create(:name => 'Starbucks - State St and Ohio St', :address => '600 N State St',
                                :state => @il, :country => @us)
    # should call location.event_location_tagged after tagging location source
    Location.any_instance.expects(:event_location_tagged).once
    @source   = @location.location_sources.create(:source_id => '4a9d9614f964a520953820e3', :source_type => 'foursquare')
    # run async job to import tags
    FoursquareApi.any_instance.stubs(:venues_detail).returns(@response)
    Resque.run!
    # should add location tags
    assert_equal ['buildings', 'cafes', 'coffee shops'], @location.reload.tag_list.sort
    # should mark location_source tag_count, tagged_at
    assert @source.reload.tagged?
    assert_equal 3, @source.reload.tag_count
    assert @source.reload.tagged_at
  end

end