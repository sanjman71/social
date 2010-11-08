# coding: utf-8
class FoursquareLocation
  
  # import tags for the specific location sources
  # note: usually called asynchronously
  def self.async_import_tags(options={})
    # initialize foursquare client, no auth required
    foursquare = FoursquareClient.new

    # initialize location sources
    location_sources = options[:location_sources] ? LocationSource.find(options[:location_sources]) : LocationSource.foursquare.all(:include => :location)

    Array(location_sources).each do |ls|
      # check if we have already imported tags from this source
      next if ls.tagged?

      begin
        venue         = foursquare.venue_details(:vid => ls.source_id)
        if venue['error']
          # foursquare returned an error, raise an exception
          raise Exception, venue['error']
        end
        category      = venue['venue']['primarycategory']
        # parse category fullpathname, nodename
        fullpathname  = category['fullpathname'] rescue nil
        nodename      = category['nodename'] rescue nil
        tag_list      = (Tagger.normalize(fullpathname) + Tagger.normalize(nodename)).uniq.sort
        location      = ls.location
        # set location tags
        location.tag_list = tag_list
        location.save
        # mark location source as tagged
        ls.tagged!
        log("[location:#{location.id}] #{location.name} tags:#{tag_list.join(',')}")
      rescue Exception => e
        log("[location:#{location.id}] #{location.name} #{__method__.to_s} #{e.message}", :error)
      end
    end

    true
  end

  def self.log(s, level = :info)
    Checkin.log(s, level)
  end
end