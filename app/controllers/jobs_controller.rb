class JobsController < ApplicationController

  # GET /jobs
  def index
    # show dj jobs
    @jobs = Delayed::Job.limit(50).order("updated_at DESC")
  end

  # PUT /jobs/backup
  def backup
    Delayed::Job.enqueue(BackupJob.new(:db => "social_#{Rails.env}"), 0)
    flash[:notice] = "Started backup job"
    redirect_to jobs_path
  end

  # PUT /jobs/sphinx
  def sphinx
    
  end

end