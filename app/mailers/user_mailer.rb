class UserMailer < ActionMailer::Base
  default :from => "outlately@jarna.com"
  
  def user_signup(user_id)
    @user = User.find(user_id)
    mail(:to => 'sanjay@jarna.com', :subject => "Outlately: member signup #{@user.handle}:#{@user.id}")
  end

  def user_invite(options)
    @invitation = Invitation.find(options[:invitation_id])
    @email      = @invitation.recipient_email
    @sender     = @invitation.sender
    @subject    = @invitation.subject || "Outlately Invitation!"
    @message    = @invitation.body

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
end
