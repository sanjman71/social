class BackupJob < Struct.new(:params)

  def logger
    case RAILS_ENV
    when 'development'
      @logger ||= Logger.new(STDOUT)
    else
      @logger ||= Logger.new("log/backup.log")
    end
  end

  def perform
    logger.info "#{Time.now}: [backup] #{params.inspect}"

    db          = params[:db]
    backup_dir  = params[:backup_dir] || Backup.default_dir
    system "bash -ic 'rake db:backup DB=#{db} BACKUP_DIR=#{backup_dir}'"

    logger.info "#{Time.now}: [backup] completed"
  end

end