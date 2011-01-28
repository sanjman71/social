class UserMailer < ActionMailer::Base
  default :from => "outlately@jarna.com"
  
  def user_signup(options)
    @user = User.find(options[:user_id])
    mail(:to => 'sanjay@jarna.com', :subject => "Outlately: member signup #{@user.handle}:#{@user.id}")
  end

  # send email to poked user's friend that somebody wants them signing up
  def user_invite_poke(options)
    @invite_poke  = InvitePoke.find(options[:invite_poke_id])
    @friend       = @invite_poke.friend
    @email        = @friend.email_address
    @invitee      = @invite_poke.invitee
    @poker        = @invite_poke.poker
    @subject      = "Outlately: Somebody wants your friend #{@invitee.handle} to sign up..."

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
    @user       = User.find(options[:user_id])
    @invite     = Invitation.find_by_token(@user.invitation_token)
    @inviter    = @invite.try(:sender)
    @email      = @inviter.try(:email_address)
    @points     = options[:points]
    @subject    = "Outlately: Your invitation was accepted!"

    mail(:to => @email, :subject => @subject)
  end

  def user_signup_to_poker(options)
    @poke     = InvitePoke.find(options[:poke_id])
    @poker    = @poke.poker
    @invitee  = @poke.invitee
    @email    = @poker.email_address
    @subject  = "Outlately: You might be interested in this user signup..."

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
