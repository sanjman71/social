class UserMailer < ActionMailer::Base
  default :from => "outlately@jarna.com"
  
  def user_signup(user)
    mail(:to => 'sanjay@jarna.com', :subject => "User signup: #{user.handle}")
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
end
