require 'test_helper'

class FriendshipTest < ActiveSupport::TestCase

  should "create friendships, but not allow duplicates" do
    Resque.reset!
    @user1      = Factory.create(:user)
    @user2      = Factory.create(:user)
    @user3      = Factory.create(:user)
    @fship12    = @user1.friendships.create!(:friend => @user2)
    @fship31    = @user3.friendships.create!(:friend => @user1)
    @fship23    = @user2.friendships.create!(:friend => @user3)
    # should not allow duplicate friendship
    assert_raise ActiveRecord::RecordInvalid do
      @user1.friendships.create!(:friend => @user2)
    end
    # should not allow duplicate inverse friendship
    assert_raise ActiveRecord::RecordInvalid do
      @user2.friendships.create!(:friend => @user1)
    end
    Resque.run!
    # all users should have friends
    assert_equal [@user2, @user3], @user1.friends + @user1.inverse_friends
    assert_equal [@user3, @user1], @user2.friends + @user2.inverse_friends
    assert_equal [@user2.id, @user3.id], @user1.reload.friend_set
    assert_equal [@user1.id, @user3.id], @user2.reload.friend_set
  end

end
