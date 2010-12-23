require 'test_helper'

class LocationshipTest < ActiveSupport::TestCase

  def setup
    @us = Factory(:us)
  end

  should "create with default values" do
    @user1      = Factory.create(:user)
    @location1  = Location.create!(:name => "Location 1", :country => @us)
    @locship    = @user1.locationships.create!(:location => @location1)
    assert_equal 0, @locship.my_checkins
    assert_equal 0, @locship.friend_checkins
    assert_equal 0, @locship.todo_checkins
  end

  should "not allow duplicates" do
    @user1      = Factory.create(:user)
    @location1  = Location.create!(:name => "Location 1", :country => @us)
    @location2  = Location.create!(:name => "Location 2", :country => @us)
    @user1.locationships.create!(:location => @location1)
    @user1.locationships.create!(:location => @location2)
    # should not allow duplicate
    assert_raise ActiveRecord::RecordInvalid do
      @user1.locationships.create!(:location => @location1)
    end
  end

  context "todo_checkins" do
    should "touch todo_at, expires_at when todo_checkins is incremented" do
      @user1      = Factory.create(:user)
      @location1  = Location.create!(:name => "Location 1", :country => @us)
      @locship    = @user1.locationships.create!(:location => @location1, :todo_checkins => 1)
      assert @locship.reload.todo_at
      assert @locship.reload.todo_expires_at
      assert_nil @locship.reload.todo_expired_at
    end

    should "not allow todo to be added if location already on checkin list" do
      @user1      = Factory.create(:user)
      @location1  = Location.create!(:name => "Location 1", :country => @us)
      @locship    = @user1.locationships.create!(:location => @location1, :my_checkins => 1)
      @locship.increment!(:todo_checkins)
      assert_equal 0, @locship.reload.todo_checkins
      assert_nil @locship.todo_at
      assert_nil @locship.todo_expires_at
      assert_nil @locship.todo_completed_at
      assert_nil @locship.todo_expired_at
    end
  end

  context "todo_days_left" do
    should "be 7 days right after todo added" do
      @user1      = Factory.create(:user)
      @location1  = Location.create!(:name => "Location 1", :country => @us)
      @locship    = @user1.locationships.create!(:location => @location1, :todo_checkins => 1)
      assert_equal 7, @locship.todo_days_left
    end

    should "be 5 days 2 days+ after todo added" do
      @user1      = Factory.create(:user)
      @location1  = Location.create!(:name => "Location 1", :country => @us)
      @locship    = @user1.locationships.create!(:location => @location1, :todo_checkins => 1)
      Timecop.travel(Time.now+2.days+1.hour) do
        assert_equal 5, @locship.todo_days_left
      end
    end

    should "be 0 days 7 days after todo added" do
      @user1      = Factory.create(:user)
      @location1  = Location.create!(:name => "Location 1", :country => @us)
      @locship    = @user1.locationships.create!(:location => @location1, :todo_checkins => 1)
      Timecop.travel(Time.now+7.days+1.hour) do
        assert_equal 0, @locship.todo_days_left
      end
    end

    should "be -2 days 9 days after todo added" do
      @user1      = Factory.create(:user)
      @location1  = Location.create!(:name => "Location 1", :country => @us)
      @locship    = @user1.locationships.create!(:location => @location1, :todo_checkins => 1)
      Timecop.travel(Time.now+9.days) do
        assert_equal -2, @locship.todo_days_left
      end
    end
  end

  context "todo reminders" do
    should "send reminder email 2 days before todo expires" do
      @user1      = Factory.create(:user)
      @user1.stubs(:email_address).returns('reminders@jarna.com')
      @location1  = Location.create(:name => "Location 1", :country => @us)
      # user adds to their todo list
      @locship    = @user1.locationships.create!(:location => @location1, :todo_checkins => 1)
      # should have no reminders right now
      assert_equal 0, @user1.send_todo_checkin_reminders
      Timecop.travel(Time.now+4.days+1.minute) do
        # should have 1 reminder to send in 4 days
        assert_equal 1, @user1.send_todo_checkin_reminders
      end
    end
  end

  context "todo resolution" do
    should "resolve as invalid when user has already checked in to a todo location" do
      @user1      = Factory.create(:user)
      @location1  = Location.create(:name => "Location 1", :country => @us)
      # user adds todo list checkin
      @locship    = @user1.locationships.create!(:location => @location1, :todo_checkins => 1)
      @locship.update_attribute(:todo_at, 3.days.ago)
      # user checked in to the location before the todo was added
      @locship.stubs(:user_first_checkin).returns(Checkin.new(:checkin_at => 7.days.ago))
      @locship.increment!(:my_checkins)
      assert_equal :invalid, @locship.todo_resolution
      assert_equal 0, @locship.reload.todo_checkins
    end

    should "resolve as completed when a user checks in to a todo location within the time limit" do
      @user1      = Factory.create(:user)
      @location1  = Location.create(:name => "Location 1", :country => @us)
      # user adds todo list checkin
      @locship    = @user1.locationships.create!(:location => @location1, :todo_checkins => 1)
      @locship.update_attribute(:todo_at, 3.days.ago)
      @points     = @user1.points
      # user checks in to the location
      @locship.increment!(:my_checkins)
      assert_equal :completed, @locship.todo_resolution
      assert_equal 0, @locship.reload.todo_checkins
      # should add 50 points
      assert_equal @points+50, @user1.reload.points
      # should send email to user
      assert_equal 1, match_delayed_jobs(/CheckinMailer/)
      assert_equal 1, match_delayed_jobs(/todo_completed/)
    end

    should "resolve as expired when a user checks in to a todo location after the time limit" do
      @user1      = Factory.create(:user)
      @location1  = Location.create(:name => "Location 1", :country => @us)
      # user adds checkin to todo list
      @locship    = @user1.locationships.create!(:location => @location1, :todo_checkins => 1)
      @locship.update_attribute(:todo_at, 10.days.ago)
      @locship.update_attribute(:todo_expires_at, 3.days.ago)
      @points     = @user1.points
      # user checks in to the location
      @locship.increment!(:my_checkins)
      # should set todo resolution as expired
      assert_equal :expired, @locship.todo_resolution
      # should reset todo_checkins
      assert_equal 0, @locship.reload.todo_checkins
      # should mark todo_expired_at, reset todo_at + todo_expires_at
      assert @locship.reload.todo_expired_at
      assert_nil @locship.reload.todo_at
      assert_nil @locship.reload.todo_expires_at
      # should subtract 10 points
      assert_equal @points-10, @user1.reload.points
      # should send email to user
      assert_equal 1, match_delayed_jobs(/CheckinMailer/)
      assert_equal 1, match_delayed_jobs(/todo_expired/)
    end
    
    should "resolve as expired when user does not checkin and time expires" do
      @user1      = Factory.create(:user)
      @location1  = Location.create(:name => "Location 1", :country => @us)
      @points     = @user1.points
      # user adds checkin to todo list
      @locship    = @user1.locationships.create!(:location => @location1, :todo_checkins => 1)
      Timecop.travel(Time.now+7.days+1.minute) do
        @locship.save
        # should set todo resolution as expired
        assert_equal :expired, @locship.todo_resolution
        # should reset todo_checkins
        assert_equal 0, @locship.reload.todo_checkins
        # should mark todo_expired_at, reset todo_at + todo_expires_at
        assert @locship.reload.todo_expired_at
        assert_nil @locship.reload.todo_at
        assert_nil @locship.reload.todo_expires_at
        # should subtract 10 points
        assert_equal @points-10, @user1.reload.points
        # should send email to user
        assert_equal 1, match_delayed_jobs(/CheckinMailer/)
        assert_equal 1, match_delayed_jobs(/todo_expired/)
      end
    end
  end
end
