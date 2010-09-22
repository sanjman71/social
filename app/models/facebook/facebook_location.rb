class FacebookLocation
  
  def self.import_tags(oauth=nil)

    # initialize location sources
    location_sources = options[:location_sources] ? options[:location_sources] : LocationSource.facebook.all(:include => :location)

    location_sources.each do |ls|
      location = ls.location
      oauth    ||= User.last.oauths.facebook.first
      
      begin
        # initialize facebook client
        facebook = FacebookClient.new(oauth.access_token)
        place    = facebook.place(ls.source_id)
        puts place.inspect
      rescue Exception => e
        puts "exception: #{e.message}"
      end

      nil
    end
  end

end