class FoursquareWorker
  # resque queue
  @queue = :normal

  def self.log(s, level = :info)
    AppLogger.log(s, nil, level)
  end

  def self.perform(method, *args)
    self.send(method, *args)
  end

  def self.source
    'foursquare'
  end

  # import checkins for the specified user, usually called asynchronously
  def self.import_checkins(options={})
    # find user oauth object
    user            = User.find_by_id(options['user_id'])
    oauth           = options['oauth_id'] ? Oauth.find_by_id(params['oauth_id']) : Oauth.find_user_oauth(user, source)
    return nil if oauth.blank?

    # find checkin log
    checkin_log     = user.checkin_logs.find_or_create_by_source(source)

    # compare last check timestamp + check interval vs current timestamp
    last_check_at   = checkin_log.last_check_at
    last_check_mins = options['minutes_since'] ? options.delete('minutes_since').to_i.minutes : Checkin.poll_interval(user)

    case
    when last_check_at.blank?
      mm = 0
    when (last_check_at + last_check_mins) > Time.zone.now
      mm, ss = (Time.zone.now-last_check_at).divmod(60)
      log("[user:#{user.id}] #{user.handle} importing #{source} skipped because last check was about #{mm} minutes ago")
      return checkin_log
    else
      mm, ss = (Time.zone.now-last_check_at).divmod(60)
    end

    begin
      # initiialize oauth object
      foursquare_oauth = Foursquare::OAuth.new(FOURSQUARE_KEY, FOURSQUARE_SECRET)
      foursquare_oauth.authorize_from_access(oauth.access_token, oauth.access_token_secret)
      
      # initialize foursquare client
      foursquare = Foursquare::Base.new(foursquare_oauth)
      if foursquare.test['response'] != 'ok'
        raise Exception, "foursquare ping failed"
      end

      # parse options
      # http://groups.google.com/group/foursquare-api/web/api-documentation
      # options - sinceid (since), l
      if options['sinceid'].present?
        # get checkins since id
        case options['sinceid']
        when 'last'
          # find last foursquare checkin
          options['sinceid'] = user.checkins.foursquare.recent.limit(1).first.try(:source_id)
        end
      end

      log("[user:#{user.id}] #{user.handle} importing #{source} checkin with options:#{options.inspect}, last checked about #{mm} minutes ago")

      # default is 20, max is 250
      if options['limit']
        options['l'] = options.delete('limit')
      end

      # get checkins, handle and log exceptions
      checkins    = foursquare.history(options)
      collection  = checkins.inject([]) do |array, checkin_hash|
        begin
          array.push(import_checkin(user, checkin_hash))
        rescue Exception => e
          log("[user:#{user.id}] #{user.handle} #{__method__.to_s} #{e.message}", :error)
        end
        array
      end.compact
    rescue Exception => e
      log("[user:#{user.id}] #{user.handle} #{__method__.to_s} #{e.message}", :error)
      checkin_log.update_attributes(:state => 'error', :checkins => 0, :last_check_at => Time.zone.now)
    else
      checkin_log.update_attributes(:state => 'success', :checkins => collection.size, :last_check_at => Time.zone.now)
      # after import event
      Checkin.event_checkins_imported(user, collection, source)
    end
    checkin_log
  end

  # import a foursquare checkin hash
  # e.g. {"id"=>141731194, "created"=>"Sun, 22 Aug 10 23:16:33 +0000", "timezone"=>"America/Chicago",
  #       "venue"=>{"id"=>4172889, "name"=>"Zed 451", "address"=>"763 N. Clark St.", "city"=>"Chicago", "state"=>"Illinois",
  #                 "geolat"=>41.8964066, "geolong"=>-87.6312161}
  #      }
  def self.import_checkin(user, checkin_hash)
    # normalize foursquare venue hash and import location
    log("[user:#{user.id}] importing foursquare checkin #{checkin_hash.inspect}");
    @venue  = checkin_hash['venue']
    @hash   = Hash['name' => @venue['name'], 'address' => @venue['address'], 'city' => @venue['city'],
                   'state' => @venue['state'], 'lat' => @venue['geolat'], 'lng' => @venue['geolong']]
    @location = LocationImport.import_location(@venue['id'].to_s, Source.foursquare, @hash)
    if @location.blank?
      raise Exception, "invalid location #{checkin_hash}"
    end
    
    # find/add checkin
    checkin_at  = Time.parse(checkin_hash['created']).utc # xxx - need to account for 'timezone' attribute
    options     = Hash[:location => @location, :checkin_at => checkin_at, :source_id => checkin_hash['id'].to_s, :source_type => Source.foursquare]
    @checkin    = user.checkins.find_by_source_id_and_source_type(options[:source_id], options[:source_type])
    return nil if @checkin
    # add checkin
    @checkin    = user.checkins.create(options)
  end

  # import tags for the specific location sources
  def self.import_tags(options={})
    # initialize foursquare client, no auth required
    foursquare = FoursquareClient.new

    # initialize location sources, using specified ids collection or all
    conditions        = options['location_sources'] ? options['location_sources'] : :all
    location_sources  = LocationSource.foursquare.find(conditions, :include => :location)

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
        log("[location:#{location.try(:id)}] #{location.try(:name)} #{__method__.to_s} #{e.message}", :error)
      end
    end

    true
  end

  # map the specified location(s) to foursquare
  def self.map_location(options={})
    locations = Location.find(options['location_ids'])

    mapped_count = 0
    locations.each do |location|
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
  

end