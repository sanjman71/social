require 'test_helper'

class InvitationTest < ActiveSupport::TestCase

  def setup
    @inviter = Factory.create(:user)
  end

  should "generate token when created" do
    @invitation = @inviter.invitations.create!(:recipient_email => 'user@outlately.com')
    assert @invitation.token
    assert @invitation.sent_at
  end

  should "send invitation email" do
    @invitation = @inviter.invitations.create!(:recipient_email => 'user@outlately.com')
    assert_equal 1, match_delayed_jobs(/user_invite/i)
  end
end