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
    dir = Rails.env == 'production' ? "/usr/apps/social/shared/backups" : "#{Rails.root}/backups"
    cmd = "rake db:backup DB=social_#{Rails.env} BACKUP_DIR=#{dir}"
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
    # find checkin_logs that need to be polled
    @checkin_logs  = CheckinLog.where("last_check_at < ?", Time.zone.now - Checkin.poll_interval).group_by(&:user)

    @checkin_logs.each_pair do |user, logs|
      logs.each do |log|
        case log.source
        when 'facebook'
          FacebookCheckin.delay.async_import_checkins(user, Hash[:since => :last, :limit => 250])
        when 'foursquare'
          FoursquareCheckin.delay.async_import_checkins(user, Hash[:sinceid => :last, :limit => 250])
        end
      end
    end

    flash[:notice] = "Polling checkins for #{@checkin_logs.keys.size} users"
  end

  # GET /jobs/todo_reminders
  def todo_reminders
    @reminders = User.all.inject(0) do |count, user|
      count += user.send_todo_checkin_reminders
      count
    end
    flash[:notice] = "Sent #{@reminders} todo reminders"
    redirect_to jobs_path
  end

end