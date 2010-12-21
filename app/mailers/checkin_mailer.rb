class CheckinMailer < ActionMailer::Base
  default :from => "outlately@jarna.com"

  def checkin_imported(options)
    @checkin  = Checkin.find_by_id(options[:checkin_id])
    @user     = @checkin.user
    @location = @checkin.location
    @email    = @user.email_address
    @points   = options[:points]
    @body     = "That checkin got you #{@points} bucks."

    unless @email.blank?
      AppLogger.log("[email:#{@user.id}:#{@email}] checkin_imported:location:#{@location.try(:name)}")
      mail(:to => @email, :subject => "You checked in at #{@location.try(:name)}", :body => @body)
    end
  end

  def todo_reminder(options)
    @user     = User.find_by_id(options[:user_id])
    @location = Location.find_by_id(options[:location_id])
    @email    = @user.email_address
    @points   = Currency.for_completed_todo

    unless @email.blank?
      AppLogger.log("[email:#{@user.id}:#{@email}] todo_reminder:location:#{@location.try(:name)}")
      mail(:to => @email, :subject => "Your planned checkin is about to expire")
    end
  end

  def todo_completed(options)
    @user     = User.find_by_id(options[:user_id])
    @email    = @user.email_address
    @location = Location.find_by_id(options[:location_id])
    @points   = options[:points]

    unless @email.blank?
      AppLogger.log("[email:#{@user.id}:#{@email}] todo_completed:location:#{@location.try(:name)}")
      mail(:to => @email, :subject => "You checked in at a planned location!")
    end
  end

  def todo_expired(options)
    @user     = User.find_by_id(options[:user_id])
    @email    = @user.email_address
    @location = Location.find_by_id(options[:location_id])
    @points   = options[:points]

    unless @email.blank?
      AppLogger.log("[email:#{@user.id}:#{@email}] todo_expired:location:#{@location.try(:name)}")
      mail(:to => @email, :subject => "You checked in at a planned location, but not in time.")
    end
  end

end
