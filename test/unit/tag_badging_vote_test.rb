require 'test_helper'

class TagBadgingVoteTest < ActiveSupport::TestCase
  
  def setup
    @user       = Factory.create(:user)
    @voter      = Factory.create(:user)
    @tag_badge  = TagBadge.create!(:name => "Shopaholic", :regex => "shopping") 
    # add user tag badge
    @badging    = @user.tag_badges.push(@tag_badge)
  end

  should "create vote, and not allow duplicates" do
    @user.tag_badging_votes.create!(:tag_badge => @tag_badge, :voter => @voter, :vote => 1)
    assert_raise ActiveRecord::RecordInvalid do
      # should not allow voter to vote again
      @user.tag_badging_votes.create!(:tag_badge => @tag_badge, :voter => @voter, :vote => 2)
    end
  end

end
