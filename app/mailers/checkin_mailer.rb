class CheckinMailer < ActionMailer::Base
  default :from => "outlately@jarna.com"

  def checkin_imported(options)
    @checkin  = Checkin.find_by_id(options[:checkin_id])
    @user     = @checkin.user
    @location = @checkin.location
    @email    = @user.email_address
    @points   = options[:points]
    @body     = "That checkin got you #{@points} points."

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
      mail(:to => @email, :subject => "Your planned checkin at #{@location.name} is about to expire")
    end
  end

  def todo_completed(options)
    @user     = User.find_by_id(options[:user_id])
    @email    = @user.email_address
    @location = Location.find_by_id(options[:location_id])
    @points   = options[:points]

    unless @email.blank?
      AppLogger.log("[email:#{@user.id}:#{@email}] todo_completed:location:#{@location.try(:name)}")
      mail(:to => @email, :subject => "Your planned checkin at #{@location.name} was completed!")
    end
  end

  def todo_expired(options)
    @user     = User.find_by_id(options[:user_id])
    @email    = @user.email_address
    @location = Location.find_by_id(options[:location_id])
    @points   = options[:points]
    @subject  = "Your planned checkin at #{@location.name} expired"

    unless @email.blank?
      AppLogger.log("[email:#{@user.id}:#{@email}] todo_expired:location:#{@location.try(:name)}")
      mail(:to => @email, :subject => @subject)
    end
  end

  def checkin_stats(options)
    @emails     = options[:emails].join(', ')
    @file       = File.read(options[:file])
    @subject    = "Outlately: checkin stats"
    # add attachment
    attachments["checkin_stats.csv"] = @file
    mail(:to => @emails, :subject => @subject)
  end

end
