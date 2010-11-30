namespace :locations do
  
  desc "Reverse geocode locations with coordinates and no city"
  task :reverse_geocode => :environment do
    limit = ENV['LIMIT'] ? ENV['LIMIT'].to_i : 100
    count = 0
    puts "#{Time.now}: reverse geocoding #{limit} locations"

    Location.with_latlng.where(:city_id => nil).order('id desc').limit(limit).each do |l|
      begin
        l.reverse_geocode
        count += 1
        sleep(1)
      rescue
        
      end
    end
    
    puts "#{Time.now}: reverse geocoded #{count} locations"
  end

end