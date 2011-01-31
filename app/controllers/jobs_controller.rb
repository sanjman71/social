class JobsController < ApplicationController
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