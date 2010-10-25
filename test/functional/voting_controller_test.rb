require 'test_helper'

class VotingControllerTest < ActionController::TestCase
  include Devise::TestHelpers
  
  context "route" do
    should route(:put, "vote/users/1/badge/3/approve").to(
      :controller => 'voting', :action => 'create', :user_id => '1', :badge_id => '3', :vote => 'approve')
  end

  def setup
    @user       = Factory.create(:user)
    @voter      = Factory.create(:user)
    @tag_badge  = TagBadge.create!(:name => "Shopaholic", :regex => "shopping") 
    # add user tag badge
    @badging    = @user.tag_badges.push(@tag_badge)
  end

  context "create" do
    setup do
      sign_in @voter
      set_beta
      put :create, :user_id => @user.id, :badge_id => @tag_badge.id, :vote => 'agree'
    end

    should "add vote" do
      assert_equal @tag_badge, assigns(:tag_badge)
      assert_equal @user, assigns(:user)
      assert_equal @voter, assigns(:voter)
      assert_equal 1, assigns(:vote)
      assert_equal 1, @user.reload.tag_badging_votes.size
    end
  end

end
