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

end