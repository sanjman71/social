class Backup
  
  def self.default_dir
    case Rails.env
    when 'development', 'test'
      "#{Rails.root}/backups"
    when 'production'
      "#{Rails.root.to_s.gsub(/releases\/\d+/, 'shared')}/backups"
    else
      "#{Rails.root}/backups"
    end
  end
end