class FacebookLocation

  # import tags for the specific location sources
  # note: usually called asynchronously
  def self.async_import_tags(options={})

    # initialize location sources
    location_sources = options[:location_sources] ? LocationSource.find(options[:location_sources]) : LocationSource.facebook.all(:include => :location)

    location_sources.each do |ls|
      # check if we have already imported tags from this source
      next if ls.tagged_at?
      
      begin
        # initialize facebook client, no token required
        facebook  = FacebookClient.new(nil)
        place     = facebook.place(ls.source_id)
        location  = ls.location
      rescue Exception => e
        # whoops
      end

      nil
    end
  end

end