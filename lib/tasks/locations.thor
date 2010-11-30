class Locations < Thor

  desc "rgeocode", "reverse geocode locations with geo coordinate and no city"
  method_options :limit => 100
  def rgeocode
    puts "#{Time.now}: reverse geocoding #{options[:limit]} locations"

    require File.expand_path('config/environment.rb')
    Location.with_latlng.where(:city_id => nil).order('id desc').limit(options[:limit]).each do |l|
      begin
        puts "#{Time.now}: reverse geocoding [#{l.id}:#{l.name}] geo:#{l.lat}:#{l.lng}"
        l.reverse_geocode
        count += 1
        sleep(1)
      rescue
        
      end
    end

    puts "#{Time.now}: completed"
  end
end