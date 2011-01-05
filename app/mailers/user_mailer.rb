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
end
