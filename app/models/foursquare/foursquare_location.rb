class FoursquareLocation
  
  def self.import_tags
    # initialize foursquare client, no auth required
    foursquare = FoursquareClient.new

    LocationSource.foursquare.all(:include => :location).each do |ls|
      begin
        venue = foursquare.venue_details(:vid => ls.source_id)
        puts venue.inspect
      rescue Exception => e
        puts "exception: #{e.message}"
      end

      nil
    end
  end

end