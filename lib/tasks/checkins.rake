namespace :checkins do

  desc "Import recent checkins"
  task :recent => :environment do
    CheckinLog.all.each do |cl|
      case cl.source
      when 'facebook'
        FacebookCheckin.import_checkins(cl.user, :since => :last)
      when 'foursquare'
        FoursquareCheckin.import_checkins(cl.user, :sinceid => :last)
      end
    end
  end

end
