class Locations < Thor

  desc "rgeocode", "reverse geocode locations with geo coordinate and no city or street address"
  method_options :limit => 100
  def rgeocode
    puts "#{Time.now}: reverse geocoding #{options[:limit]} locations"

    require File.expand_path('config/environment.rb')
    Location.with_latlng.where(:city_id => nil, :street_address => nil).order('id desc').limit(options[:limit]).each do |l|
      begin
        puts "#{Time.now}: [#{l.id}:#{l.name}] reverse geocoding geo:#{l.lat}:#{l.lng}"
        result = l.reverse_geocode
        raise Exception, "" if !result
        sleep(1)
      rescue Exception => e
        puts "#{Time.now}: [reverse geocoding error] #{e.message}"
      end
    end

    puts "#{Time.now}: completed"
  end
end