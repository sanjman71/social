require 'test_helper'

class LocationshipTest < ActiveSupport::TestCase
  fixtures :all

  should "create with default values" do
    @user1      = Factory.create(:user)
    @location1  = Location.create!(:name => "Location 1", :country => countries(:us))
    @locship    = @user1.locationships.create!(:location => @location1)
    assert_equal 0, @locship.my_checkins
    assert_equal 0, @locship.friend_checkins
    assert_equal 0, @locship.todo_checkins
  end

  should "not allow duplicates" do
    @user1      = Factory.create(:user)
    @location1  = Location.create!(:name => "Location 1", :country => countries(:us))
    @location2  = Location.create!(:name => "Location 2", :country => countries(:us))
    @user1.locationships.create!(:location => @location1)
    @user1.locationships.create!(:location => @location2)
    # should not allow duplicate
    assert_raise ActiveRecord::RecordInvalid do
      @user1.locationships.create!(:location => @location1)
    end
  end

end
