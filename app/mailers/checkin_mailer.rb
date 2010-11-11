class CheckinMailer < ActionMailer::Base
  default :from => "outlately@jarna.com"
  
  def todo_completed(user, location, points)
    @user     = user
    @email    = @user.email_address
    @location = location
    @points   = points

    return if @email.blank?
    mail(:to => 'sanjay@jarna.com', :subject => "You checked in!")
  end

  def todo_expired(user, location, points)
    @user     = user
    @email    = @user.email_address
    @location = location
    @points   = points

    return if @email.blank?
    mail(:to => 'sanjay@jarna.com', :subject => "You checked in, but a bit too late.")
  end
end
