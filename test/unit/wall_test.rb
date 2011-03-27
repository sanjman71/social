require 'test_helper'

class WallTest < ActiveSupport::TestCase
  def setup
    # users
    @user1 = Factory(:user, :handle => "User 1")
    @user2 = Factory(:user, :handle => "User 2")
    @user3 = Factory(:user, :handle => "User 3")

    @user2.follow(@user1)
    @user3.follow(@user1)

    # checkins
    @chicago      = cities(:chicago)
    @chicago_sbux = Location.create!(:name => "Chicago Starbucks", :country => @us, :city => @chicago)
    @checkin      = @user1.checkins.create!(Factory.attributes_for(:foursquare_checkin, :location => @chicago_sbux))
  end

  should "find or create wall" do
    @wall = Wall.find_or_create(:checkin => @checkin)
    assert @wall.valid?
    # should find same wall
    assert_equal @wall, Wall.find_or_create(:checkin => @checkin)
  end

  should "use set wall updated_at to checkin timestamp" do
    @wall = Wall.find_or_create(:checkin => @checkin)
    assert_equal @checkin.checkin_at, @wall.updated_at
  end

  should "use location name as wall name" do
    @wall = Wall.find_or_create(:checkin => @checkin)
    assert_equal "Chicago Starbucks", @wall.name
  end

  should "set member_set based on followers" do
    @wall = Wall.create!(:checkin => @checkin, :location => @checkin.location)
    assert_equal [@user1.id, @user2.id, @user3.id], @wall.member_set
    # should find member handles
    assert_equal [@user1.handle, @user2.handle, @user3.handle], @wall.member_handles
    # should link user to wall
    assert_equal [@wall], Wall.find_all_by_member(@user1)
    assert_equal @wall, Wall.find_by_member(@user1)
  end

  should "post message to wall" do
    @wall = Wall.create!(:checkin => @checkin, :location => @checkin.location)
    Timecop.travel(Time.now+9.minutes) do
      @msg  = @wall.wall_messages.create!(:sender => @user1, :message => "message 1")
      assert_equal 1, @wall.reload.messages_count
      # should set wall updated_at to wall's most recent message
      assert_equal @msg.created_at.to_i, @wall.updated_at.to_i
    end
  end

  should "not allow post to wall from a non-member" do
    @wall   = Wall.create!(:checkin => @checkin, :location => @checkin.location)
    @user4  = Factory(:user, :handle => "User 4")
    @msg    = @wall.wall_messages.create(:sender => @user4, :message => "message 1")
    assert @msg.invalid?
  end

end