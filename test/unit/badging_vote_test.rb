require 'test_helper'

class BadgingVoteTest < ActiveSupport::TestCase
  
  def setup
    @user     = Factory.create(:user)
    @voter    = Factory.create(:user)
    @badge    = Badge.create!(:name => "Shopaholic", :regex => "shopping") 
    # add user badge
    @badging  = @user.badges.push(@badge)
  end

  should "create vote, and not allow duplicates" do
    @user.badging_votes.create!(:badge => @badge, :voter => @voter, :vote => 1)
    assert_raise ActiveRecord::RecordInvalid do
      # should not allow voter to vote again
      @user.badging_votes.create!(:badge => @badge, :voter => @voter, :vote => 2)
    end
  end

end
