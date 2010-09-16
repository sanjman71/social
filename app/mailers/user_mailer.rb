class UserMailer < ActionMailer::Base
  default :from => "outlately@jarna.com"
  
  def user_signup(user)
    mail(:to => 'sanjay@jarna.com', :subject => "User signup: #{user.handle}")
  end
end
