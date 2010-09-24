class FacebookLocation
  
  def self.import_tags(options={})

    # initialize location sources
    location_sources = options[:location_sources] ? options[:location_sources] : LocationSource.facebook.all(:include => :location)

    location_sources.each do |ls|
      location = ls.location
      # not sure we need to be authenticated for this
      oauth    ||= User.last.oauths.facebook.first
      
      begin
        # initialize facebook client
        facebook = FacebookClient.new(oauth.access_token)
        place    = facebook.place(ls.source_id)
        puts place.inspect
      rescue Exception => e
        EXCEPTIONS_LOGGER.info("#{Time.now}: [error] [import tags:#{ls.id}] #{e.message}:#{e.backtrace}")
      end

      nil
    end
  end

end