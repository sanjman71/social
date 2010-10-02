namespace :db do

  desc "Backup the database, (options: DB=xyz, BACKUP_DIR=home/backups)"
  task :backup => :environment do
    mysqldump           = 'mysqldump'
    mysqldump_options   = '--single-transaction --quick'
    username            = ActiveRecord::Base.configurations[Rails.env]['username']
    password            = ActiveRecord::Base.configurations[Rails.env]['password']
    host                = ActiveRecord::Base.configurations[Rails.env]['host']
    database_name       = ENV["DB"].to_s
    backup_dir          = ENV["BACKUP_DIR"] ? ENV["BACKUP_DIR"] : "#{Rails.root}/backups"
    
    if database_name.blank?
      puts "no DB specified"
      exit
    end

    timestamp           = Time.now.strftime("%Y%m%d%H%M%S")
    backup_dir          = "#{backup_dir}"
    backup_file         = "#{database_name}_#{timestamp}.sql.gz"
    
    cmd = "#{mysqldump} #{mysqldump_options} -u#{username} -p#{password} -h#{host} #{database_name} | gzip -c > #{backup_dir}/#{backup_file}"
    
    puts "#{Time.now}: creating backup in backups/#{backup_file}"
    system "mkdir -p #{backup_dir}"
    system cmd
    puts "#{Time.now}: created backup"
    
    dir         = Dir.new(backup_dir)
    max_backups = ENV["MAX"] ? ENV["MAX"].to_i : 25
    all_backups = dir.entries[2..-1].sort.reverse

    unwanted_backups = all_backups[max_backups..-1] || []
    for unwanted_backup in unwanted_backups
      FileUtils.rm_rf(File.join(backup_dir, unwanted_backup))
      puts "#{Time.now}: deleted #{unwanted_backup}" 
    end

    puts "#{Time.now}: deleted #{unwanted_backups.length} backups, #{all_backups.length - unwanted_backups.length} backups available" 
  end

  desc "Restore the database from the specified file (options: FILE=xyz.sql, DB=xyz)"
  task :restore => :environment do
    if ENV["FILE"].blank?
      puts "no FILE specified"
      exit
    end

    load_file = ENV["FILE"]

    if !File.exists?(load_file)
      puts "file #{load_file} does not exist"
      exit
    end
    
    mysqlload           = 'mysql'
    username            = ActiveRecord::Base.configurations[Rails.env]['username']
    password            = ActiveRecord::Base.configurations[Rails.env]['password']
    host                = ActiveRecord::Base.configurations[Rails.env]['host']
    database_name       = ENV["DB"]

    if database_name.blank?
      puts "no DB specified"
      exit
    end

    if load_file.match(/.gz$/)
      # unzip, then reset load file name
      cmd = "gunzip #{load_file}"
      puts "#{Time.now}: unzipping #{load_file}"
      system cmd
      load_file = load_file.gsub(".gz", '')
    end
    
    cmd = "#{mysqlload} -u#{username} -p#{password} -h#{host} #{database_name} < #{load_file}"
    puts "#{Time.now}: loading file '#{load_file}' into database '#{database_name}'"
    system cmd
    puts "#{Time.now}: completed"
  end

end