require 'test_helper'

class PlannedCheckinTest < ActiveSupport::TestCase

  def setup
    @us       = Factory(:us)
    @il       = Factory(:il, :country => @us)
    @chicago  = Factory(:chicago, :state => @il, :timezone => Factory(:timezone_chicago))
    @user     = Factory(:user)
    @user.email_addresses.create!(:address => 'user@outlately.com')
    @chi_sbux = Location.create!(:name => "Chicago Starbucks", :country => @us, :city => @chicago)
  end

  context "create" do
    should "set active to 1" do
      @pcheckin = @user.planned_checkins.create!(:location => @chi_sbux)
      assert_equal 1, @pcheckin.reload.active
      assert @pcheckin.reload.active?
    end

    should "set expires_at to be in 7 days" do
      @pcheckin = @user.planned_checkins.create!(:location => @chi_sbux)
      assert @pcheckin.expires_at
      assert_equal 7, @pcheckin.days_left
    end

    should "set locationship todo_checkins to 1" do
      @pcheckin = @user.planned_checkins.create!(:location => @chi_sbux)
      work_off_delayed_jobs
      @locship  = @user.locationships.find_by_location_id(@chi_sbux.id)
      assert_equal 1, @locship.todo_checkins
    end

    should "set default going_at" do
      @pcheckin = @user.planned_checkins.create!(:location => @chi_sbux)
      assert_nil @pcheckin.going_at
      assert_equal "Plans on going soon", @pcheckin.going
    end

    should "set going_at to 3 days" do
      @pcheckin = @user.planned_checkins.create!(:location => @chi_sbux, :going_at => 3.days.from_now)
      assert @pcheckin.going_at
      assert_equal "Plans on going in 3 days", @pcheckin.going
    end

    should "not allow if there is an active planned checkin" do
      @pcheckin1 = @user.planned_checkins.create!(:location => @chi_sbux)
      work_off_delayed_jobs
      Timecop.travel(Time.now+3.days) do
        assert_false @pcheckin1.expired?
        # expire planned checkins
        PlannedCheckin.expire_all
        # should not allow
        @pcheckin2 = @user.planned_checkins.create(:location => @chi_sbux)
        assert @pcheckin2.invalid?
      end
    end

    should "allow if there are no active planned checkins" do
      @pcheckin1 = @user.planned_checkins.create!(:location => @chi_sbux)
      work_off_delayed_jobs
      Timecop.travel(Time.now+7.days+1.minute) do
        assert @pcheckin1.expired?
        # expire planned checkins
        PlannedCheckin.expire_all
        # should allow
        @pcheckin2 = @user.planned_checkins.create(:location => @chi_sbux)
        assert @pcheckin2.valid?
      end
    end
  end

  context "planned checkin expired" do
    should "reset locationship todo_checkins to 0 after expiry" do
      @pcheckin1 = @user.planned_checkins.create!(:location => @chi_sbux)
      work_off_delayed_jobs
      Timecop.travel(Time.now+7.days+1.minute) do
        # expire planned checkins
        PlannedCheckin.expire_all
        @locship = @user.locationships.find_by_location_id(@chi_sbux.id)
        assert_equal 0, @locship.todo_checkins
      end
    end
  end

  context "planned checkin reminders" do
    should "send reminder email 2 days before planned checkin expires" do
      @pcheckin1 = @user.planned_checkins.create!(:location => @chi_sbux)
      work_off_delayed_jobs
      Timecop.travel(Time.now+1.day) do
        # should have no reminders in 1 day
        assert_equal 0, @user.reload.send_planned_checkin_reminders
      end
      Timecop.return
      Timecop.travel(Time.now+4.days+1.minute) do
        # should have 1 reminder to send in 4 days
        assert_equal 1, @user.reload.send_planned_checkin_reminders
      end
    end
  end

  context "planned checkin resolution" do
    should "resolve as completed when a user checks in to a planned location before it expires" do
      @pcheckin1  = @user.planned_checkins.create!(:location => @chi_sbux)
      work_off_delayed_jobs
      Timecop.travel(Time.now+1.day) do
        @points  = @user.points
        # user checks in to location
        @checkin = @user.checkins.create!(Factory.attributes_for(:foursquare_checkin, :location => @chi_sbux,
                                                                 :checkin_at => Time.zone.now))
        work_off_delayed_jobs
        # should be no active planned checkins on user's list
        assert_equal 0, @user.planned_checkins.active.count
        # should reset locationship todo_checkins to 0
        assert_equal 0, @user.locationships.find_by_location_id(@chi_sbux.id).todo_checkins
        # should add 10 points for a checkin and 50 points for completing a todo
        assert_equal @points+60, @user.reload.points
        # should send email to user
        assert_equal 1, match_delayed_jobs(/CheckinMailer/)
        assert_equal 1, match_delayed_jobs(/todo_completed/)
      end
    end
    
    should "resolve as expired when a user checks in to a planned location after it expires" do
      @pcheckin1  = @user.planned_checkins.create!(:location => @chi_sbux)
      work_off_delayed_jobs
      Timecop.travel(Time.now+7.days+1.minute) do
        @points  = @user.points
        # user checks in to location
        @checkin = @user.checkins.create!(Factory.attributes_for(:foursquare_checkin, :location => @chi_sbux,
                                                                 :checkin_at => Time.zone.now))
        work_off_delayed_jobs
        # should be no active planned checkins on user's list
        assert_equal 0, @user.planned_checkins.active.count
        # should reset locationship todo_checkins to 0
        assert_equal 0, @user.locationships.find_by_location_id(@chi_sbux.id).todo_checkins
        # should add 10 points for a checkin and -10 points for an expired todo
        assert_equal @points, @user.reload.points
        # should send email to user
        assert_equal 1, match_delayed_jobs(/CheckinMailer/)
        assert_equal 1, match_delayed_jobs(/todo_expired/)
      end
    end
  end

end