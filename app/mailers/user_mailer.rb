class UserMailer < ActionMailer::Base
  default :from => "outlately@jarna.com"

  def self.log(s, level = :info)
    AppLogger.log(s, nil, level)
  end

  def admin_emails
    "sanjay@jarna.com, marchick@gmail.com"
  end

  def user_signup(options)
    @user     = User.find(options['user_id'])
    @emails   = admin_emails

    self.class.log("[email:admin]: user signup #{@user.handle}:#{@user.id}")

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

    if @email.blank?
      # send email to admins instead, with a modified subject
      @email    = admin_emails
      @subject  = "Outlately: friend poke sent here because #{@friend.handle}:#{@friend.id} doesn't have an email address"
    end

    self.class.log("[email:#{@friend.id}:#{@email}]: re:#{@invitee.handle}:#{@invitee.id}, poker:#{@poker.handle}:#{@poker.id}")

    mail(:to => @email, :subject => @subject)
  end

  def user_invite(options)
    @invitation = Invitation.find(options['invitation_id'])
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

    self.class.log("[email:#{@inviter.id}:#{@email}]: invite:#{@invite.id} to user:#{@user.id}:#{@user.handle}")

    mail(:to => @email, :subject => @subject)
  end

  def user_signup_to_poker(options)
    @poke     = InvitePoke.find(options['poke_id'])
    @poker    = @poke.poker
    @invitee  = @poke.invitee
    @email    = @poker.email_address
    @subject  = "Outlately: You might be interested in this user signup..."

    self.class.log("[email:#{@poker.id}:#{@email}]: signup:#{@invitee.id}:#{@invitee.handle}")

    mail(:to => @email, :subject => @subject)
  end

  def user_learns(options)
    @user           = User.find(options['user_id'])
    @learn_handle   = options['learn_handle']
    @common_friends = options['common_friends']
    @email          = @user.email_address
    @subject        = "Outlately: You wanted to know more about #{@learn_handle}..."

    self.class.log("[email:#{@user.id}:#{@email}]: user_learns:#{@learn_handle}")

    mail(:to => @email, :subject => @subject)
  end

  def user_message(options)
    @sender   = User.find(options['sender_id'])
    @to       = User.find(options['to_id'])
    @email    = @to.email_address
    @text     = options['body']
    @subject  = "Outlately: #{@sender.handle} sent you a message..."

    self.class.log("[email:#{@to.id}:#{@email}]: from:#{@sender.id}:#{@sender.handle}")

    mail(:to => @email, :subject => @subject)
  end

  def user_share_drink_message(options)
    @sender   = User.find(options['sender_id'])
    @to       = User.find(options['to_id'])
    @email    = @to.email_address
    @subject  = "Outlately: Want to share a drink with..."

    self.class.log("[email:#{@to.id}:#{@email}]: from:#{@sender.id}:#{@sender.handle}")

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

  def user_nearby_realtime_checkins(options)
    @user     = User.find(options['user_id'])
    @checkin  = Checkin.find(options['checkin_id'])
    @checkins = Checkin.find(options['checkin_ids']) rescue []
    @email    = @user.email_address
    @subject  = "Outlately: Who's out and about right now..."

    mail(:to => @email, :subject => @subject)
  end

  def user_matching_checkins(options)
    @user     = User.find(options['user_id'])
    @checkins = Checkin.find(options['checkin_ids']) rescue []
    @email    = @user.email_address
    @subject  = "Outlately: Check out who else is out and about..."

    mail(:to => @email, :subject => @subject)
  end
end
