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
        venue = foursquare.venue_details(:vid => ls.source_id)
        if venue['error']
          # foursquare returned an error, raise an exception
          raise Exception, venue['error']
        end
        # parse category tags
        category  = venue['venue']['primarycategory']
        tag_list  = category_tag_list(category)
        # add location tags, duplicate tags are ignored
        location  = ls.location
        location.tag_list.add(tag_list)
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

  # map the specified location(s) to foursquare
  def self.map(locations, options={})
    mapped_count = 0
    Array(locations).each do |location|
      # skip if location already has a foursquare mapping
      next if location.location_sources.foursquare.count > 0

      # skip if location is not mappable or is missing a street address
      if !location.mappable? or location.street_address.blank?
        next
      end

      log("[location:#{location.id}] #{location.name}:#{location.street_address} searching foursquare ...")

      # initialize foursquare client, no auth required
      foursquare  = FoursquareClient.new
      mapped      = false

      begin
        results = foursquare.venue_search(:q => location.name, :geolat => location.lat, :geolong => location.lng)
        venues  = results['groups'].inject([]) do |array, group|
          type  = group['type'] # e.g. 'Matching Places', 'Matching Tags'
          array += group['venues']
        end
        venues.each do |venue|
          # we could check distance here
          # distance = venue['distance']
          log("[location:#{location.id}] matching foursquare:#{venue.inspect}")
          # match venue against our database using sphinx
          locations = LocationFinder.match({'name' => venue['name'], 'address' => venue['address'],
                                            'city' => venue['city'], 'state' => venue['state']})
          if locations.collect(&:id) == [location.id]
            # the venue matched the location being mapped
            # add location source
            location.location_sources.create(:source_id => venue['id'], :source_type => Source.foursquare)
            # add location tags
            category  = venue['primarycategory']
            tag_list  = category_tag_list(category)
            location.tag_list.add(tag_list)
            location.save
            mapped = true
            mapped_count += 1
            break
          end
        end
      rescue Exception => e
        log("[location:#{location.id}] #{location.name} #{__method__.to_s} #{e.message}", :error)
      end
    end
    
    # return the number of locations mapped
    mapped_count
  end

  # category
  # e.g. {"id"=>79048, "fullpathname"=>"Food:Burgers", "nodename"=>"Burgers", "iconurl"=>"http://foursquare.com/img/categories/food/burger.png"}
  def self.category_tag_list(category)
    # parse category fullpathname, nodename
    fullpathname  = category['fullpathname'] rescue nil
    nodename      = category['nodename'] rescue nil
    tag_list      = (Tagger.normalize(fullpathname) + Tagger.normalize(nodename)).uniq.sort
    tag_list
  end

  def self.log(s, level = :info)
    Checkin.log(s, level)
  end
end