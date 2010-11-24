class JobsController < ApplicationController
  skip_before_filter :check_beta, :if => :auth_token?
  privilege_required 'admin', :unless => :auth_token?

  # GET /jobs
  def index
    # show dj jobs
    @jobs = Delayed::Job.limit(50).order("updated_at DESC")
  end

  # GET /jobs/backup
  # PUT /jobs/backup
  def backup
    app = 'outlately'
    dir = Rails.env == 'production' ? "/usr/apps/#{app}/shared/backups" : "#{Rails.root}/backups"
    cmd = "rake db:backup DB=#{app}_#{Rails.env} BACKUP_DIR=#{dir}"
    Delayed::Job.enqueue(RakeJob.new(:cmd => cmd), 0)
    flash[:notice] = "Queued backup job"
    redirect_to jobs_path
  end

  # GET /jobs/sphinx
  # PUT /jobs/sphinx
  def sphinx
    cmd = "rake ts:index"
    Delayed::Job.enqueue(RakeJob.new(:cmd => cmd), 0)
    flash[:notice] = "Queued sphinx job"
    redirect_to jobs_path
  end

  # GET /jobs/poll_checkins
  def poll_checkins
    # find users with oauths and checkin logs that need to be updated
    @users = User.with_oauths.joins(:checkin_logs).
                  where(:"checkin_logs.last_check_at".lt => Time.zone.now - Checkin.poll_interval).select("users.*").all

    @users.each do |user|
      user.checkin_logs.each do |log|
        case log.source
        when 'facebook'
          FacebookCheckin.delay.async_import_checkins(user, Hash[:since => :last, :limit => 250])
        when 'foursquare'
          FoursquareCheckin.delay.async_import_checkins(user, Hash[:sinceid => :last, :limit => 250])
        end
      end
    end

    flash[:notice] = "Polling checkins for #{@users.size} users: #{@users.collect(&:handle).join(", ")}"
    redirect_to jobs_path
  end

  # GET /jobs/send_todo_reminders
  def send_todo_reminders
    @reminders = User.all.inject(0) do |count, user|
      count += user.send_todo_checkin_reminders
      count
    end
    flash[:notice] = "Sent #{@reminders} todo reminders"
    redirect_to jobs_path
  end

  # GET /jobs/top
  def top
    @top = Machine.top
    @log = params[:log].to_i == 1

    if @log
      file = "#{Rails.root}/log/machine.log"
      line = "#{Time.now.to_s(:datetime_compact)}: #{@top.join(', ')}\n"
      File.open(file, 'a') {|f| f.write(line) }
    end

    render(:action => 'index')
  end

end