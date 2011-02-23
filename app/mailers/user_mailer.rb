class UserMailer < ActionMailer::Base
  default :from => "outlately@jarna.com"

  def log(s, level = :info)
    AppLogger.log(s, nil, level)
  end

  def track(id)
    key   = Time.zone.now.to_s(:date_yyyymmdd) + ":emails"
    redis = RedisSocket.new
    redis.hincrby(key, id, 1)
  end

  def admin_emails
    "sanjay@jarna.com, marchick@gmail.com"
  end

  def user_signup(options)
    @user     = User.find(options['user_id'])
    @emails   = admin_emails

    log("[email:admin]: user signup #{@user.handle}:#{@user.id}")

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

    # log and track
    log("[email:#{@friend.id}]: #{@email} re:#{@invitee.handle}:#{@invitee.id}, poker:#{@poker.handle}:#{@poker.id}")
    track("invite_poke")

    mail(:to => @email, :subject => @subject)
  end

  def user_invite(options)
    @invitation = Invitation.find(options['invitation_id'])
    @email      = @invitation.recipient_email
    @sender     = @invitation.sender
    @subject    = @invitation.subject || "Outlately Invitation!"
    @message    = @invitation.body

    # log and track
    log("[email:#{@sender.id}]: #{@email} invited by #{@sender.handle}")
    track("invite")

    mail(:to => @email, :subject => @subject)
  end

  def user_invite_accepted(options)
    @user       = User.find(options['user_id'])
    @invite     = Invitation.find_by_token(@user.invitation_token)
    @inviter    = @invite.try(:sender)
    @email      = @inviter.try(:email_address)
    @points     = options['points']
    @subject    = "Outlately: Your invitation was accepted!"

    # log and track
    log("[email:#{@inviter.id}]: #{@email} invite:#{@invite.id} to user:#{@user.id}:#{@user.handle}")
    track("invite_accepted")

    mail(:to => @email, :subject => @subject)
  end

  def user_signup_to_poker(options)
    @poke     = InvitePoke.find(options['poke_id'])
    @poker    = @poke.poker
    @invitee  = @poke.invitee
    @email    = @poker.email_address
    @subject  = "Outlately: You might be interested in this user signup..."

    # log and track
    log("[email:#{@poker.id}]: #{@email} signup:#{@invitee.id}:#{@invitee.handle}")
    track("signup_poker")

    mail(:to => @email, :subject => @subject)
  end

  def user_learn_more(options)
    @user           = User.find(options['user_id'])
    @about_user     = User.find(options['about_user_id'])
    @common_friends = options['common_friends']
    @email          = @user.email_address
    @subject        = "Outlately: You wanted to know more about #{@about_user.handle}..."

    # log and track
    log("[email:#{@user.id}]: #{@email} user_learn_more:#{@about_user.handle}")
    track("learn_more")

    mail(:to => @email, :subject => @subject)
  end

  def user_message(options)
    @sender   = User.find(options['sender_id'])
    @to       = User.find(options['to_id'])
    @email    = @to.email_address
    @text     = options['body']
    @subject  = "Outlately: #{@sender.handle} sent you a message..."

    # log and track
    log("[email:#{@to.id}]: #{@email} from:#{@sender.id}:#{@sender.handle}")
    track("message")

    mail(:to => @email, :subject => @subject)
  end

  def user_be_there_soon_message(options)
    @sender   = User.find(options['sender_id'])
    @to       = User.find(options['to_id'])
    @checkin  = Checkin.find(options['checkin_id'])

    @email    = @to.email_address
    @subject  = "Outlately: from #{@sender.handle}, re: your checkin at #{@checkin.location.try(:name)}..."

    # log and track
    log("[email:#{@to.id}]: #{@email} from:#{@sender.id}:#{@sender.handle}")
    track("be_there_soon")

    mail(:to => @email, :subject => @subject)
  end

  def user_share_drink_message(options)
    @sender   = User.find(options['sender_id'])
    @to       = User.find(options['to_id'])
    @email    = @to.email_address

    if options['checkin_id']
      @checkin  = Checkin.find(options['checkin_id'])
    elsif options['todo_id']
      @todo     = PlannedCheckin.find(options["todo_id"])
    end

    if @checkin
      @subject  = "Outlately: from #{@sender.handle}, re: your checkin at #{@checkin.location.try(:name)}..."
    elsif @todo
      @subject  = "Outlately: from #{@sender.handle}, re: your planned checkin at #{@todo.location.try(:name)}..."
    end

    # log and track
    log("[email:#{@to.id}]: #{@email} from:#{@sender.id}:#{@sender.handle}")
    track("share_drink")

    mail(:to => @email, :subject => @subject)
  end

  def user_add_todo_request(options)
    @sender   = User.find(options['sender_id'])
    @to       = User.find(options['to_id'])
    @email    = @to.email_address
    @subject  = "Outlately: #{@sender.handle} sent you a message..."

    # log and track
    log("[email:#{@to.id}]: #{@email} from:#{@sender.id}:#{@sender.handle}")
    track("add_todo")

    mail(:to => @email, :subject => @subject)
  end

  def user_badge_added(options)
    @badging  = Badging.find(options['badging_id'])
    @user     = @badging.user
    @badge    = @badging.badge
    @email    = @user.email_address
    @subject  = "Outlately: Your Social DNA has been updated with a new badge..."

    # log and track
    log("[email:#{@user.id}]: #{@email} new social dna badge")
    track("badge_added")

    mail(:to => @email, :subject => @subject)
  end

  def user_friend_realtime_checkin(options)
    @user     = User.find(options['user_id'])
    @checkin  = Checkin.find(options['checkin_id'])

    @email    = @user.email_address
    @token    = @user.oauths.facebook.first.try(:access_token).to_s
    @subject  = "Outlately: #{@checkin.user.try(:handle)} checked in at #{@checkin.location.try(:name)}..."

    @message_url = message_user_url(:id => @checkin.user.try(:id), :object_type => 'checkin',
                                    :object_id => @checkin.id, :message => 'bts', :token => @token,
                                    'utm_campaign' => 'friend-realtime-checkin', 'utm_medium' => 'email',
                                    'utm_source' => 'outlately')
    unless Rails.env == 'test'
      # shorten url
      @short_url = Url.shorten(@message_url)
    end

    # log and track
    log("[email:#{@user.id}]: #{@email} friend #{@checkin.user.try(:handle)} realtime checkin")
    track("friend_realtime_checkin")

    mail(:to => @email, :subject => @subject)
  end

  def user_nearby_realtime_checkins(options)
    @user     = User.find(options['user_id'])
    @checkin  = Checkin.find(options['checkin_id'])
    @location = @checkin.location
    @checkins = Checkin.find(options['checkin_ids']) rescue []

    @email    = @user.email_address
    @token    = @user.oauths.facebook.first.try(:access_token).to_s
    @subject  = "Outlately: Who's out and about #{@location.try(:name)} right now..."

    # log and track
    log("[email:#{@user.id}]: #{@email} realtime checkins")
    track("realtime_checkins")

    mail(:to => @email, :subject => @subject)
  end

  def user_daily_checkins(options)
    @user         = User.find(options['user_id'])
    @my_checkins  = Checkin.find(options['my_checkin_ids']) rescue []
    @checkins     = Checkin.find(options['checkin_ids']) rescue []
    @email        = @user.email_address
    @subject      = "Outlately: Your daily checkin email..."

    case @my_checkins.size
    when 1
      @checkin  = @my_checkins.first
      @text     = "We noticed your checkin at #{@checkin.location.try(:name)} yesterday."
    else
      @text     = "We noticed your #{@my_checkins.size} checkins yesterday."
    end

    # log and track
    log("[email:#{@user.id}]: #{@email} daily checkins")
    track("daily_checkins")

    mail(:to => @email, :subject => @subject)
  end

end
