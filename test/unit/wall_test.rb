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

  should "set member_set based on followers" do
    @wall = Wall.create!(:checkin => @checkin, :location => @checkin.location)
    assert_equal [@user1.id, @user2.id, @user3.id], @wall.member_set
  end
  
  should "post message to wall" do
    @wall = Wall.create!(:checkin => @checkin, :location => @checkin.location)
    @msg  = @wall.wall_messages.create!(:sender => @user1, :message => "message 1")
    assert_equal 1, @wall.reload.messages_count
  end

  should "not allow post to wall from a non-member" do
    @wall   = Wall.create!(:checkin => @checkin, :location => @checkin.location)
    @user4  = Factory(:user, :handle => "User 4")
    @msg    = @wall.wall_messages.create(:sender => @user4, :message => "message 1")
    assert @msg.invalid?
  end

end