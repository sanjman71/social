class CheckinMailer < ActionMailer::Base
  default :from => "outlately@jarna.com"
  
  def todo_reminder(user, location)
    @user     = user
    @email    = @user.email_address
    @location = location

    unless @email.blank?
      AppLogger.log("[email:#{@user.id}:#{@email}] todo_reminder:location:#{@location.try(:name)}")
      mail(:to => @email, :subject => "Your planned checkin is about to expire")
    end
  end

  def todo_completed(user, location, points)
    @user     = user
    @email    = @user.email_address
    @location = location
    @points   = points

    unless @email.blank?
      AppLogger.log("[email:#{@user.id}:#{@email}] todo_completed:location:#{@location.try(:name)}")
      mail(:to => @email, :subject => "You checked in!")
    end
  end

  def todo_expired(user, location, points)
    @user     = user
    @email    = @user.email_address
    @location = location
    @points   = points

    unless @email.blank?
      AppLogger.log("[email:#{@user.id}:#{@email}] todo_expired:location:#{@location.try(:name)}")
      mail(:to => @email, :subject => "You checked in, but a bit too late.")
    end
  end
  
end
