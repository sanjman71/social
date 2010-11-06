require 'test_helper'

class LocationshipTest < ActiveSupport::TestCase

  def setup
    @us = Factory(:us)
  end

  should "create with default values" do
    @user1      = Factory.create(:user)
    @location1  = Location.create(:name => "Location 1", :country => @us)
    @locship    = @user1.locationships.create!(:location => @location1)
    assert_equal 0, @locship.my_checkins
    assert_equal 0, @locship.friend_checkins
    assert_equal 0, @locship.planned_checkins
  end

  should "not allow duplicates" do
    @user1      = Factory.create(:user)
    @location1  = Location.create(:name => "Location 1", :country => @us)
    @location2  = Location.create(:name => "Location 2", :country => @us)
    @user1.locationships.create!(:location => @location1)
    @user1.locationships.create!(:location => @location2)
    # should not allow duplicate
    assert_raise ActiveRecord::RecordInvalid do
      @user1.locationships.create!(:location => @location1)
    end
  end

  should "touch planned_at when planned_checkins is incremented" do
    @user1      = Factory.create(:user)
    @location1  = Location.create(:name => "Location 1", :country => @us)
    @locship    = @user1.locationships.create!(:location => @location1, :planned_checkins => 1)
    assert @locship.reload.planned_at
  end
end
