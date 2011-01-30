class UserMailer < ActionMailer::Base
  default :from => "outlately@jarna.com"

  def self.log(s, level = :info)
    AppLogger.log(s, nil, level)
  end

  def user_signup(options)
    @user     = User.find(options['user_id'])
    @emails   = 'sanjay@jarna.com, marchick@gmail.com'

    self.class.log("[email]: user signup #{@user.handle}:#{@user.id}")

    mail(:to => @emails, :subject => "Outlately: member signup #{@user.handle}:#{@user.id}")
  end

  # send email to poked user's friend that somebody wants them signing up
  def user_invite_poke(options)
    @invite_poke  = InvitePoke.find(options['invite_poke_id'])
    @friend       = @invite_poke.friend
    @email        = @friend.email_address
    @invitee      = @invite_poke.invitee
    @poker        = @invite_poke.poker
    @subject      = "Outlately: Can you invite your friend #{@invitee.handle} to sign up..."

    self.class.log("[email]: user invite poke to #{@email}, friend:#{@friend.handle}:#{@friend.id}, re:#{@invitee.handle}:#{@invitee.id}, poker:#{@poker.handle}:#{@poker.id}")

    mail(:to => @email, :subject => @subject)
  end

  def user_invite(options)
    @invitation = Invitation.find(options[:invitation_id])
    @email      = @invitation.recipient_email
    @sender     = @invitation.sender
    @subject    = @invitation.subject || "Outlately Invitation!"
    @message    = @invitation.body

    mail(:to => @email, :subject => @subject)
  end

  def user_invite_accepted(options)
    @user       = User.find(options['user_id'])
    @invite     = Invitation.find_by_token(@user.invitation_token)
    @inviter    = @invite.try(:sender)
    @email      = @inviter.try(:email_address)
    @points     = options['points']
    @subject    = "Outlately: Your invitation was accepted!"

    self.class.log("[email]: user invite accepted to #{@email}, inviter:#{@inviter.handle}:#{@inviter.id}")

    mail(:to => @email, :subject => @subject)
  end

  def user_signup_to_poker(options)
    @poke     = InvitePoke.find(options['poke_id'])
    @poker    = @poke.poker
    @invitee  = @poke.invitee
    @email    = @poker.email_address
    @subject  = "Outlately: You might be interested in this user signup..."

    self.class.log("[email]: user signup via poke to #{@email}, signup:#{@invitee.handle}:#{@invitee.id}")

    mail(:to => @email, :subject => @subject)
  end

  def user_send_message(options)
    @sender   = User.find(options[:sender_id])
    @to       = User.find(options[:to_id])
    @email    = @to.email_address
    @text     = options[:body]
    @subject  = "Outlately: #{@sender.handle} sent you a message..."

    mail(:to => @email, :subject => @subject)
  end

  def user_badge_added(options)
    @badging  = Badging.find(options[:badging_id])
    @user     = @badging.user
    @badge    = @badging.badge
    @email    = @user.email_address
    @subject  = "Outlately: Your Social DNA includes a new badge..."

    mail(:to => @email, :subject => @subject)
  end

  def user_matching_checkins(options)
    @user     = User.find(options[:user_id])
    @checkins = Checkin.find(options[:checkin_ids]) rescue []
    @email    = @user.email_address
    @subject  = "Outlately: Check out who else is out and about..."

    mail(:to => @email, :subject => @subject)
  end
end
