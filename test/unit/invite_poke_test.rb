require 'test_helper'

class InvitePokeTest < ActiveSupport::TestCase

  def setup
    @invitee  = Factory.create(:user, :member => false)
    @friend   = Factory.create(:user, :member => true)
    @poker    = Factory.create(:user, :member => true)
    @invitee.friends.push(@friend)
  end

  should "create and queue email" do
    @poke = InvitePoke.find_or_create(@invitee, @poker)
    assert @poke.valid?
    assert match_delayed_jobs(/user_invite_poke/)
  end

  should "use recent poke if another poke by same poker is sent within 10 minutes" do
    @poke = InvitePoke.find_or_create(@invitee, @poker)
    Timecop.travel(Time.now+9.minutes) do
      @poke2 = InvitePoke.find_or_create(@invitee, @poker)
      assert_equal @poke, @poke2
    end
  end

  should "create new poke if a different poker sends a poke" do
    @poker2 = Factory.create(:user, :member => true)
    @poke1  = InvitePoke.find_or_create(@invitee, @poker)
    @poke2  = InvitePoke.find_or_create(@invitee, @poker2)
    assert @poke2.valid?
    assert_not_equal @poke1.id, @poke2.id
  end

end