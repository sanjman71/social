require 'test_helper'

class CheckinTest < ActiveSupport::TestCase

  # turn off transactional fixtures here so we can test sphinx
  self.use_transactional_fixtures = false

  def setup
    ThinkingSphinx::Test.init
    @us       = Factory(:us)
    @il       = Factory(:il, :country => @us)
    @chicago  = Factory(:chicago, :state => @il, :timezone => Factory(:timezone_chicago))
    @user     = Factory.create(:user)
  end

  def teardown
    [Checkin, CheckinLog, Location, Country, State, City, User].each { |o| o.delete_all }
  end

  context "import foursquare checkins" do
    context "all user checkins" do
      should "create checkin log, add checkin, create checkin alert, delay sphinx rebuild" do
        ThinkingSphinx::Test.run do
          # create user oauth token
          @oauth    = @user.oauths.create(:name => 'foursquare', :access_token => '12345')
          @hash     = Hash["id"=>141731194, "created"=>"Sun, 22 Aug 10 23:16:33 +0000", "timezone"=>"America/Chicago",
                           "venue"=>{"id"=>4172889, "name"=>"Zed 451", "address"=>"763 N. Clark St.", "city"=>"Chicago",
                                     "state"=>"Illinois", "geolat"=>41.8964066, "geolong"=>-87.6312161}
                          ]
          # should add user points for oauth
          assert_equal 5, @user.reload.points
          # should add alert
          assert_equal 1, @user.reload.alerts.count
          # stub oauth calls
          Foursquare::Base.any_instance.stubs(:test).returns(Hash['response' => 'ok'])
          Foursquare::Base.any_instance.stubs(:history).returns([@hash])
          @checkin_log = FoursquareCheckin.async_import_checkins(@user)
          assert @checkin_log.valid?
          # should have 1 checkin
          assert_equal 1, @checkin_log.checkins
          assert_equal 'success', @checkin_log.state
          assert_equal 'foursquare', @checkin_log.source
          assert_equal 1, @user.checkins.count
          assert_equal 1, @user.checkins_count
          # should add alert
          assert_false @user.suggestionable?
          assert_equal 1, @user.reload.alerts.count
          # assert @user.reload.low_activity_alert_at
          # should add user points for checkin
          assert_equal 10, @user.reload.points
          # should add sphinx delayed_job
          delayed_jobs = Delayed::Job.limit(1).order('id desc').collect(&:handler)
          assert delayed_jobs[0].match(/SphinxJob/)
          # assert delayed_jobs[1].match(/SuggestionAlgorithm/)
        end
      end
      
      should "skip check if last check was within x minutes" do
        # create user oauth token
        @oauth        = @user.oauths.create(:name => 'foursquare', :access_token => '12345')
        # create checkin 30 minutes ago
        @checkin_log1 = @user.checkin_logs.create(:source => 'foursquare', :state => 'success', :checkins => 1,
                                                  :last_check_at => Time.zone.now-30.minutes)
        # checkin log timestamp should be the same
        @checkin_log2 = FoursquareCheckin.async_import_checkins(@user)
        assert_equal @checkin_log1.last_check_at, @checkin_log2.last_check_at                    
      end
    end

    context "single checkin" do
      should "create location, add checkin" do
        ThinkingSphinx::Test.run do
          @hash     = Hash["id"=>141731194, "created"=>"Sun, 22 Aug 10 23:16:33 +0000", "timezone"=>"America/Chicago",
                           "venue"=>{"id"=>4172889, "name"=>"Zed 451", "address"=>"763 N. Clark St.", "city"=>"Chicago",
                                     "state"=>"Illinois", "geolat"=>41.8964066, "geolong"=>-87.6312161}
                          ]
          @checkin  = FoursquareCheckin.import_checkin(@user, @hash)
          assert @checkin.valid?
          assert_equal '141731194', @checkin.source_id
          assert_equal 'foursquare', @checkin.source_type
          # user should have 1 checkin
          assert_equal 1, @user.reload.checkins.count
          assert_equal 1, @user.reload.checkins_count
          # location should have 1 checkin
          @location = @checkin.location
          assert_equal 1, @location.reload.checkins.count
          assert_equal 1, @location.reload.checkins_count
          # should use same checkin if we try it again
          @checkin2 = FoursquareCheckin.import_checkin(@user, @hash)
          assert_nil @checkin1
          assert_equal 1, Checkin.count
          assert_equal 1, Location.count
        end
      end
    end
  end
  
  context "import facebook checkin" do
    context "all user checkins" do
      should "create checkin log, add checkin" do
        ThinkingSphinx::Test.run do
          # create user oauth token
          @oauth    = @user.oauths.create(:name => 'facebook', :access_token => '12345')
          @hash     = Hash["id"=>"461630895812", "from"=>{"name"=>"Sanjay Kapoor", "id"=>"633015812"},
                           "place"=>{"id"=>"117669674925118", "name"=>"Bull & Bear",
                                     "location"=>{"street"=>"431 N Wells St", "city"=>"Chicago", "state"=>"IL", "zip"=>"60654-4512",
                                                  "latitude"=>41.890177, "longitude"=>-87.633815}}, 
                           "application"=>nil, "created_time"=>"2010-08-28T22:33:53+0000"
                          ]
          # should add user points for oauth
          assert_equal 5, @user.reload.points
          # should add alert
          assert_equal 1, @user.reload.alerts.count
          # stub facebook client calls
          FacebookClient.any_instance.stubs(:checkins).returns(Hash['data' => [@hash]])
          @checkin_log = FacebookCheckin.async_import_checkins(@user)
          assert @checkin_log.valid?
          # should have 1 checkin
          assert_equal 1, @checkin_log.checkins
          assert_equal 'success', @checkin_log.state
          assert_equal 'facebook', @checkin_log.source
          # should add alert
          assert_false @user.suggestionable?
          assert_equal 1, @user.reload.alerts.count
          # assert @user.reload.low_activity_alert_at
          # should add sphinx delayed_job
          delayed_jobs = Delayed::Job.limit(1).order('id desc').collect(&:handler)
          assert delayed_jobs[0].match(/SphinxJob/)
          # assert delayed_jobs[1].match(/SuggestionAlgorithm/)
        end
      end
    end

    context "single checkin" do
      should "create location, add checkin" do
        ThinkingSphinx::Test.run do
          @hash     = Hash["id"=>"461630895812", "from"=>{"name"=>"Sanjay Kapoor", "id"=>"633015812"},
                           "place"=>{"id"=>"117669674925118", "name"=>"Bull & Bear",
                                     "location"=>{"street"=>"431 N Wells St", "city"=>"Chicago", "state"=>"IL", "zip"=>"60654-4512",
                                                  "latitude"=>41.890177, "longitude"=>-87.633815}}, 
                           "application"=>nil, "created_time"=>"2010-08-28T22:33:53+0000"
                          ]
          @checkin  = FacebookCheckin.import_checkin(@user, @hash)
          assert @checkin.valid?
          assert_equal '461630895812', @checkin.source_id
          assert_equal 'facebook', @checkin.source_type
          # user should have 1 checkin
          assert_equal 1, @user.reload.checkins.count
          assert_equal 1, @user.reload.checkins_count
          # location should have 1 checkin
          @location = @checkin.location
          assert_equal 1, @location.reload.checkins.count
          assert_equal 1, @location.reload.checkins_count
          # should use same checkin if we try it again
          @checkin2 = FacebookCheckin.import_checkin(@user, @hash)
          assert_nil @checkin2
          assert_equal 1, Checkin.count
          assert_equal 1, Location.count
        end
      end
    end
  end

end