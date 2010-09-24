# coding: utf-8
class FoursquareLocation
  
  def self.import_tags(options={})
    # initialize foursquare client, no auth required
    foursquare = FoursquareClient.new

    # initialize location sources
    location_sources = options[:location_sources] ? options[:location_sources] : LocationSource.foursquare.all(:include => :location)

    location_sources.each do |ls|
      # check if we have already imported tags from this source
      next if ls.tagged_at?

      begin
        venue         = foursquare.venue_details(:vid => ls.source_id)
        category      = venue['venue']['primarycategory']
        # parse category fullpathname, nodename
        fullpathname  = category['fullpathname'] rescue nil
        nodename      = category['nodename'] rescue nil
        tag_list      = (Tagger.normalize(fullpathname) + Tagger.normalize(nodename)).uniq.sort
        location      = ls.location
        # set location tags
        location.tag_list = tag_list
        location.save
        # mark location source tagged_at
        ls.tagged_at  = Time.zone.now
        ls.tag_count  = tag_list.size
        ls.save
        LOCATIONS_LOGGER.info("#{Time.now}: [location:#{location.id}] #{location.name} tags:#{tag_list.join(',')}")
      rescue Exception => e
        EXCEPTIONS_LOGGER.info("#{Time.now}: [error] [import tags:#{ls.id}] #{e.message}:#{e.backtrace}")
      end
    end

    true
  end

end