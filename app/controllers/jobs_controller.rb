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