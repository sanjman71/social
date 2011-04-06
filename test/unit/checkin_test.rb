require 'test_helper'

class CheckinTest < ActiveSupport::TestCase

  # turn off transactional fixtures here so we can test sphinx
  self.use_transactional_fixtures = false

  def setup
    @chicago  = cities(:chicago)
    @user     = Factory(:user)
  end

  def teardown
    DatabaseCleaner.clean
  end

  context "checkin points" do
    should "add 10 points for a user checkin" do
      @chicago_sbux = Location.create!(:name => "Chicago Starbucks", :country => @us, :city => @chicago)
      @checkin = @user.checkins.create!(Factory.attributes_for(:foursquare_checkin, :location => @chicago_sbux))                                     
      assert_equal 10, @user.reload.points
    end
  end

  context "import single foursquare checkin" do
    setup do
      @checkin_hash =
       {"id"=>"4d96b18897d06ea88d020a0b", "createdAt"=>1301721480, "type"=>"checkin",
        "timeZone"=>"America/Chicago",
        "venue"=>{"id"=>"4c047ed13f03b713f8275241", "name"=>"Moe's Cantina",
          "contact"=>{},
          "location"=>{"address"=>"155 W. Kinzie", "crossStreet"=>"in River North", "city"=>"Chicago", "state"=>"IL",
                       "postalCode"=>"60654", "lat"=>41.88883, "lng"=>-87.633208},
                       "categories"=>[
                         {"id"=>"4bf58dd8d48988d1db931735", "name"=>"Tapas Restaurants", "icon"=>"http://foursquare.com/img/categories/food/default.png", "parents"=>["Food"], "primary"=>true},
                         {"id"=>"4bf58dd8d48988d1c1941735", "name"=>"Mexican Restaurants", "icon"=>"http://foursquare.com/img/categories/food/default.png", "parents"=>["Food"]},
                         {"id"=>"4bf58dd8d48988d116941735", "name"=>"Bars", "icon"=>"http://foursquare.com/img/categories/nightlife/default.png", "parents"=>["Nightlife Spots"]}],
                         "verified"=>false,
                         "stats"=>{"checkinsCount"=>1691, "usersCount"=>1041}, "todos"=>{"count"=>0}}, "photos"=>{"count"=>0, "items"=>[]},
                         "comments"=>{"count"=>0, "items"=>[]}}
      # @checkin_hash = Hash["id"=>141731194, "created"=>"Sun, 22 Aug 10 23:16:33 +0000", "timezone"=>"America/Chicago",
      #                      "venue"=>{"id"=>4172889, "name"=>"Zed 451", "address"=>"763 N. Clark St.", "city"=>"Chicago",
      #                                "state"=>"Illinois", "geolat"=>41.8964066, "geolong"=>-87.6312161}
      #                     ]
    end

    should "create location, add checkin, add locationship" do
      Resque.reset!
      @checkin = FoursquareWorker.import_checkin(@user, @checkin_hash)
      # @checkin  = FoursquareCheckin.import_checkin(@user, @checkin_hash)
      assert @checkin.valid?
      assert_equal '4d96b18897d06ea88d020a0b', @checkin.source_id
      assert_equal 'foursquare', @checkin.source_type
      # should add user checkin
      assert_equal 1, @user.reload.checkins.count
      assert_equal 1, @user.reload.checkins_count
      # location should have 1 checkin
      @location = @checkin.location
      assert_equal 1, @location.reload.checkins.count
      assert_equal 1, @location.reload.checkins_count
      # run jobs
      Resque.run!
      # should add locationship and increment my_checkins count
      assert_equal 1, @user.locationships.count
      assert_equal [@location.id], @user.locationships.collect(&:location_id)
      assert_equal [1], @user.locationships.collect(&:my_checkins)
      # should use same checkin if we try it again
      @checkin2 = FoursquareWorker.import_checkin(@user, @checkin_hash)
      assert_equal @checkin2, @checkin
      assert_equal 1, Checkin.count
      assert_equal 1, Location.count
    end

    should "update locationship friend_checkins for a user's existing friends" do
      Resque.reset!
      # create user friendship
      @friend   = Factory.create(:user)
      @fship    = @user.friendships.create!(:friend => @friend)
      @checkin  = FoursquareWorker.import_checkin(@user, @checkin_hash)
      assert @checkin.valid?
      @location = @checkin.location
      # run jobs
      Resque.run!
      # should add friend locationship
      assert_equal 1, @friend.locationships.count
      assert_equal [@location.id], @friend.locationships.collect(&:location_id)
      assert_equal [1], @friend.locationships.collect(&:friend_checkins)
      assert_equal [0], @friend.locationships.collect(&:my_checkins)
    end

    should "update locationship friend_checkins for friends added later" do
      Resque.reset!
      @checkin  = FoursquareWorker.import_checkin(@user, @checkin_hash)
      assert @checkin.valid?
      # update checkin timestamp to make sure its created before any friends
      @checkin.update_attribute(:created_at, @checkin.created_at - 1.month)
      @location = @checkin.location
      # run jobs
      Resque.run!
      # user adds friend
      @friend   = Factory.create(:user)
      @fship    = @user.friendships.create!(:friend => @friend)
      # run jobs
      Resque.run!
      # should add friend locationship with friend_checkins counter value
      assert_equal 1, @friend.locationships.count
      assert_equal [@location.id], @friend.locationships.collect(&:location_id)
      assert_equal [1], @friend.locationships.collect(&:friend_checkins)
      assert_equal [0], @friend.locationships.collect(&:my_checkins)
    end
  end

  context "import all foursquare checkins" do
    should "create checkin log and add checkin" do
      # create user oauth token
      @oauth    = @user.oauths.create(:provider => 'foursquare', :access_token => '12345')
      @response =
      {"meta" => {"code" => 200},
       "response" => {"checkins" => {"count"=>1, "items" => [
         {"id"=>"4d96b18897d06ea88d020a0b", "createdAt"=>1301721480, "type"=>"checkin",
           "timeZone"=>"America/Chicago",
           "venue"=>{"id"=>"4c047ed13f03b713f8275241", "name"=>"Moe's Cantina",
             "contact"=>{},
             "location"=>{"address"=>"155 W. Kinzie", "crossStreet"=>"in River North", "city"=>"Chicago", "state"=>"IL",
                          "postalCode"=>"60654", "lat"=>41.88883, "lng"=>-87.633208},
                          "categories"=>[
                            {"id"=>"4bf58dd8d48988d1db931735", "name"=>"Tapas Restaurants", "icon"=>"http://foursquare.com/img/categories/food/default.png", "parents"=>["Food"], "primary"=>true},
                            {"id"=>"4bf58dd8d48988d1c1941735", "name"=>"Mexican Restaurants", "icon"=>"http://foursquare.com/img/categories/food/default.png", "parents"=>["Food"]},
                            {"id"=>"4bf58dd8d48988d116941735", "name"=>"Bars", "icon"=>"http://foursquare.com/img/categories/nightlife/default.png", "parents"=>["Nightlife Spots"]}],
                            "verified"=>false,
                            "stats"=>{"checkinsCount"=>1691, "usersCount"=>1041}, "todos"=>{"count"=>0}}, "photos"=>{"count"=>0, "items"=>[]},
                            "comments"=>{"count"=>0, "items"=>[]}}
        ]}
      }}
      FoursquareApi.any_instance.stubs(:user_checkins).returns(@response)
      @checkin_log = FoursquareWorker.import_checkins('user_id' => @user.id)
      assert @checkin_log.valid?
      # should have 1 checkin
      assert_equal 1, @checkin_log.checkins
      assert_equal 'success', @checkin_log.state
      assert_equal 'foursquare', @checkin_log.source
      assert_equal 1, @user.checkins.count
      assert_equal 1, @user.reload.checkins_count
    end

    should "skip check if last check was within x minutes" do
      # create user oauth token
      @oauth        = @user.oauths.create(:provider => 'foursquare', :access_token => '12345')
      # timestamp checkin log 5 minutes ago
      @checkin_log1 = @user.checkin_logs.create(:source => 'foursquare', :state => 'success', :checkins => 1,
                                                :last_check_at => Time.zone.now-5.minutes)
      # should not change checkin log timestamp
      @checkin_log2 = FoursquareWorker.import_checkins('user_id' => @user.id)
      assert_equal @checkin_log1.last_check_at.to_i, @checkin_log2.last_check_at.to_i
    end
  end

  context "import single facebook checkin" do
    should "create chicago location, add checkin" do
      @hash = Hash["id"=>"461630895812", "from"=>{"name"=>"Sanjay Kapoor", "id"=>"633015812"},
                   "place"=>{"id"=>"117669674925118", "name"=>"Bull & Bear",
                             "location"=>{"street"=>"431 N Wells St", "city"=>"Chicago", "state"=>"IL",
                                          "zip"=>"60654-4512", "latitude"=>41.890177, "longitude"=>-87.633815}}, 
                   "application"=>nil, "created_time"=>"2010-08-28T22:33:53+0000"
                  ]
      @checkin  = FacebookWorker.import_checkin(@user, @hash)
      assert @checkin.valid?
      assert_equal '461630895812', @checkin.source_id
      assert_equal 'facebook', @checkin.source_type
      # user should have 1 checkin
      assert_equal 1, @user.reload.checkins.count
      assert_equal 1, @user.reload.checkins_count
      # location should have correct city, state and have 1 checkin
      @location = @checkin.location
      assert_equal 'Chicago', @location.city.name
      assert_equal 'IL', @location.state.code
      assert_equal 1, @location.reload.checkins.count
      assert_equal 1, @location.reload.checkins_count
      # should use same checkin if we try it again
      @checkin2 = FacebookWorker.import_checkin(@user, @hash)
      assert_nil @checkin2
      assert_equal 1, Checkin.count
      assert_equal 1, Location.count
    end
    
    # SK: look into this
    # should "create massachusetts location, add checkin" do
    #   # create state
    #   @ma   = Factory(:state, :name => 'Massachusetts', :code => "MA", :country => @us)
    #   @hash = Hash["id"=>"9999999999",
    #                "from"=>{"name"=>"Sanjay Kapoor", "id"=>"633015812"},
    #                "place"=>{"id"=>"108154322559927", "name"=>"L'aroma Cafe Bakery",
    #                          "location"=>{"street"=>"15 Spencer St", "city"=>"West Newton", "state"=>"MA",
    #                                       "zip"=>"02465-2428", "latitude"=>42.348691, "longitude"=>-71.225649}}, 
    #                "application"=>nil, "created_time"=>"2010-08-28T22:33:53+0000"
    #               ]
    #   ThinkingSphinx::Test.run do
    #     # should create checkin with valid location
    #     @checkin  = FacebookCheckin.import_checkin(@user, @hash)
    #     assert @checkin.valid?
    #     @location = @checkin.location
    #     assert @location.valid?
    #     assert_equal 'West Newton', @location.city.name
    #     assert_equal 'MA', @location.state.code
    #   end
    # end
  end

  context "import all facebook checkins" do
    setup do
      # create user oauth token
      @oauth  = @user.oauths.create!(:provider => 'facebook', :access_token => '12345')
      # setup checkin hash
      @hash   = Hash["id"=>"461630895812", "from"=>{"name"=>"Sanjay Kapoor", "id"=>"633015812"},
                     "place"=>{"id"=>"117669674925118", "name"=>"Bull & Bear",
                               "location"=>{"street"=>"431 N Wells St", "city"=>"Chicago", "state"=>"IL",
                                            "zip"=>"60654-4512", "latitude"=>41.890177, "longitude"=>-87.633815}}, 
                     "application"=>nil, "created_time"=>"2010-08-28T22:33:53+0000"
                    ]
    end

    should "create checkin log, add checkin" do
      # stub facebook client calls
      FacebookClient.any_instance.stubs(:checkins).returns(Hash['data' => [@hash]])
      @checkin_log = FacebookWorker.import_checkins('user_id' => @user.id)
      assert @checkin_log.valid?
      # should have 1 checkin
      assert_equal 1, @checkin_log.checkins
      assert_equal 'success', @checkin_log.state
      assert_equal 'facebook', @checkin_log.source
    end
    
    # should "add delayed job to import friend checkins" do
    #   Delayed::Job.delete_all
    #   ThinkingSphinx::Test.run do
    #     # create user friendship
    #     @friend   = Factory.create(:user)
    #     @fship    = @user.friendships.create!(:friend => @friend)
    #     # should add delayed job to update locationships
    #     assert_equal 1, match_delayed_jobs(/async_update_locationships/)
    #     # stub facebook client calls
    #     FacebookClient.any_instance.stubs(:checkins).returns(Hash['data' => [@hash]])
    #     @checkin_log = FacebookCheckin.async_import_checkins(:user_id => @user.id)
    #     assert @checkin_log.valid?
    #     # should add delayed job to import friend checkins
    #     assert_equal 1, match_delayed_jobs(/async_import_checkins/)
    #   end
    # end
  end

end