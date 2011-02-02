class CheckinMailer < ActionMailer::Base
  default :from => "outlately@jarna.com"

  def newbie_favorite_added(options)
    @location = Location.find_by_id(options['location_id'])
    @user     = User.find_by_id(options['user_id'])
    @email    = @user.email_address

    unless @email.blank?
      AppLogger.log("[email:#{@user.id}:#{@email}] newbie_favorite_added:location:#{@location.try(:name)}")
      mail(:to => @email, :subject => "Outlately: You marked #{@location.try(:name)} as a favorite place...")
    end
  end

  def checkin_imported(options)
    @checkin  = Checkin.find_by_id(options[:checkin_id])
    @user     = @checkin.user
    @location = @checkin.location
    @email    = @user.email_address
    @points   = options[:points]
    @subject  = "Outlately: You checked in at #{@location.try(:name)}..."

    unless @email.blank?
      AppLogger.log("[email:#{@user.id}:#{@email}] checkin_imported:location:#{@location.try(:name)}")
      mail(:to => @email, :subject => @subject)
    end
  end

  def todo_added(options)
    @pcheckin = PlannedCheckin.find_by_id(options['planned_checkin_id'])
    @user     = @pcheckin.user
    @location = @pcheckin.location
    @email    = @user.email_address
    @points   = options['points']
    @subject  = "Outlately: You planned a checkin at #{@location.name}..."

    unless @email.blank?
      AppLogger.log("[email:#{@user.id}:#{@email}] todo_added:location:#{@location.try(:name)}")
      mail(:to => @email, :subject => @subject)
    end
  end

  def todo_reminder(options)
    @user     = User.find_by_id(options[:user_id])
    @location = Location.find_by_id(options[:location_id])
    @email    = @user.email_address
    @points   = Currency.for_completed_todo
    @subject  = "Your planned checkin at #{@location.name} is about to expire..."

    unless @email.blank?
      AppLogger.log("[email:#{@user.id}:#{@email}] todo_reminder:location:#{@location.try(:name)}")
      mail(:to => @email, :subject => @subject)
    end
  end

  def todo_completed(options)
    @user     = User.find_by_id(options[:user_id])
    @email    = @user.email_address
    @location = Location.find_by_id(options[:location_id])
    @points   = options[:points]
    @subject  = "Your planned checkin at #{@location.name} was completed!"

    unless @email.blank?
      AppLogger.log("[email:#{@user.id}:#{@email}] todo_completed:location:#{@location.try(:name)}")
      mail(:to => @email, :subject => @subject)
    end
  end

  def todo_expired(options)
    @user     = User.find_by_id(options[:user_id])
    @email    = @user.email_address
    @location = Location.find_by_id(options[:location_id])
    @points   = options[:points]
    @subject  = "Your planned checkin at #{@location.name} expired..."

    unless @email.blank?
      AppLogger.log("[email:#{@user.id}:#{@email}] todo_expired:location:#{@location.try(:name)}")
      mail(:to => @email, :subject => @subject)
    end
  end

  def todo_joined(options)
    @orig_todo  = PlannedCheckin.find_by_id(options[:orig_todo])
    @orig_user  = @orig_todo.user
    @new_todo   = PlannedCheckin.find_by_id(options[:new_todo])
    @new_user   = @new_todo.user
    # send email to 'original' user
    @email      = @orig_user.email_address
    @subject    = "Outlately: #{@new_user.handle} is planning on joining you..."

    case @new_todo.going_days_left
    when 0
      @going = 'today'
    when 1
      @going = 'tomorrow'
    else
      @going = 'soon'
    end

    unless @email.blank?
      AppLogger.log("[email:#{@orig_user.id}:#{@email}] todo_joined:#{@new_todo.id}:user:#{@new_todo.user.id}:location:#{@new_todo.location.try(:name)}")
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
