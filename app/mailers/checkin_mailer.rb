class CheckinMailer < ActionMailer::Base
  default :from => "outlately@jarna.com"
  
  def todo_reminder(user, location)
    @user     = user
    @email    = @user.email_address
    @location = location
    @points   = Currency.for_completed_todo

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
      mail(:to => @email, :subject => "You checked in at a planned location!")
    end
  end

  def todo_expired(user, location, points)
    @user     = user
    @email    = @user.email_address
    @location = location
    @points   = points

    unless @email.blank?
      AppLogger.log("[email:#{@user.id}:#{@email}] todo_expired:location:#{@location.try(:name)}")
      mail(:to => @email, :subject => "You checked in at a planned location, but not in time.")
    end
  end

  def checkin_imported(checkin, points=0)
    @user     = checkin.user
    @location = checkin.location
    @email    = @user.email_address
    @points   = points
    @body     = "That checkin got you #{points} bucks."

    unless @email.blank?
      AppLogger.log("[email:#{@user.id}:#{@email}] checkin_imported:location:#{@location.try(:name)}")
      mail(:to => @email, :subject => "You checked in at #{@location.try(:name)}", :body => @body)
    end
  end
end
