require 'test_helper'

class CheckinTest < ActiveSupport::TestCase

  def setup
    @us       = Factory(:us)
    @il       = Factory(:il, :country => @us)
    @chicago  = Factory(:chicago, :state => @il, :timezone => Factory(:timezone_chicago))
  end

  context "import foursquare checkin" do
    should "create location, add checkin" do
      @hash     = Hash["id"=>141731194, "created"=>"Sun, 22 Aug 10 23:16:33 +0000", "timezone"=>"America/Chicago",
                       "venue"=>{"id"=>4172889, "name"=>"Zed 451", "address"=>"763 N. Clark St.", "city"=>"Chicago",
                                 "state"=>"Illinois", "geolat"=>41.8964066, "geolong"=>-87.6312161}
                      ]
      @user     = Factory.create(:user)
      @checkin  = FoursquareCheckin.import_checkin(@user, @hash)
      assert @checkin.valid?
      assert_equal '141731194', @checkin.source_id
      assert_equal 'fs', @checkin.source_type
      # user should have 1 checkin
      assert_equal 1, @user.reload.checkins.count
      # location should have 1 checkin
      @location = @checkin.location
      assert_equal 1, @location.reload.checkins.count
      # should return same checkin object and use same location if we try it again
      @checkin2 = FoursquareCheckin.import_checkin(@user, @hash)
      assert_equal @checkin, @checkin2
      assert_equal 1, Location.count
    end
  end
  
  context "import facebook checkin" do
    should "create location, add checkin" do
      @hash     = Hash["id"=>"461630895812", "from"=>{"name"=>"Sanjay Kapoor", "id"=>"633015812"},
                       "place"=>{"id"=>"117669674925118", "name"=>"Bull & Bear",
                                 "location"=>{"street"=>"431 N Wells St", "city"=>"Chicago", "state"=>"IL", "zip"=>"60654-4512",
                                              "latitude"=>41.890177, "longitude"=>-87.633815}}, 
                       "application"=>nil, "created_time"=>"2010-08-28T22:33:53+0000"
                      ]
      @user     = Factory.create(:user)
      @checkin  = FacebookCheckin.import_checkin(@user, @hash)
      assert @checkin.valid?
      assert_equal '461630895812', @checkin.source_id
      assert_equal 'fb', @checkin.source_type
      # user should have 1 checkin
      assert_equal 1, @user.reload.checkins.count
      # location should have 1 checkin
      @location = @checkin.location
      assert_equal 1, @location.reload.checkins.count
      # should return same checkin object and use same location if we try it again
      @checkin2 = FacebookCheckin.import_checkin(@user, @hash)
      assert_equal @checkin, @checkin2
      assert_equal 1, Location.count
    end
  end

end