require 'test_helper'

class FriendshipTest < ActiveSupport::TestCase

  should "create friendships, but not allow duplicates" do
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
    # all users should have friends
    assert_equal [@user2, @user3], @user1.friends + @user1.inverse_friends
    assert_equal [@user3, @user1], @user2.friends + @user2.inverse_friends
    assert_equal [@user2.id, @user3.id], @user1.friend_ids
    assert_equal [@user1.id, @user3.id], @user2.friend_ids
  end

end
