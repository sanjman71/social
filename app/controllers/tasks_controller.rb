class TasksController < ApplicationController
  skip_before_filter :check_beta

  # GET /
  def index
  end

  # GET /backup
  def backup
    dir = Rails.env == 'production' ? "/usr/apps/social/shared/backups" : "#{Rails.root}/backups"
    cmd = "rake db:backup DB=social_#{Rails.env} BACKUP_DIR=#{dir}"
    Delayed::Job.enqueue(RakeJob.new(:cmd => cmd), 0)
    flash[:notice] = "Queued backup job"
    redirect_to(root_path) and return
  end
  
end