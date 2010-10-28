require 'test_helper'

class FriendshipTest < ActiveSupport::TestCase
  
  should "create friendships, but not allow duplicates" do
    @user1      = Factory.create(:user)
    @user2      = Factory.create(:user)
    @friendship = @user1.friendships.create!(:friend => @user2)
    # should not allow same friendship
    assert_raise ActiveRecord::RecordInvalid do
      @user1.friendships.create!(:friend => @user2)
    end
    # should not allow inverse friendship
    assert_raise ActiveRecord::RecordInvalid do
      @user2.friendships.create!(:friend => @user1)
    end
    # both users should have friends
    assert_equal [@user2], @user1.friends + @user1.inverse_friends
    assert_equal [@user1], @user2.friends + @user2.inverse_friends
  end

end
