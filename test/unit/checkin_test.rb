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
      @checkin  = Checkin.import_foursquare_checkin(@user, @hash)
      assert @checkin.valid?
      # user should have 1 checkin
      assert_equal 1, @user.reload.checkins.count
      # location should have 1 checkin
      @location = @checkin.location
      assert_equal 1, @location.reload.checkins.count
      # should return same checkin object if we try it again
      @checkin2 = Checkin.import_foursquare_checkin(@user, @hash)
      assert_equal @checkin, @checkin2
    end
  end

end