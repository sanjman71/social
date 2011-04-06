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
      # parse options
      # http://groups.google.com/group/foursquare-api/web/api-documentation
      # options - afterTimestamp, beforeTimestamp, limit, offset
      if options['afterTimestamp'].present?
        # get checkins since id
        case options['afterTimestamp']
        when 'last'
          # find last foursquare checkin
          last_checkin_at = user.checkins.foursquare.recent.limit(1).first.try(:checkin_at)
          if last_checkin_at
            # convert to utc
            options['afterTimestamp'] = last_checkin_at.utc.to_i
          else
            # no checkins so start at beginning
            options.delete('afterTimestamp')
          end
        end
      end

      log("[user:#{user.id}] #{user.handle} importing #{source} checkin with options:#{options.inspect}, last checked about #{mm} minutes ago")

      client    = FoursquareApi.new(oauth.access_token_secret.present? ? oauth.access_token_secret : oauth.access_token)
      response  = client.user_checkins('self')

      # check response
      if response['meta']['code'] != 200
        log("[user:#{user.id}] #{user.handle} foursquare oauth error #{response['meta']}")
        return nil
      end

      # get checkins, handle and log exceptions
      checkins    = response['response']['checkins']
      count       = checkins['count']

      log("[user:#{user.id}] #{user.handle} found #{count} foursquare checkin(s)")

      collection  = checkins['items'].inject([]) do |array, checkin_hash|
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
  # e.g.
  # {"id"=>"4d96b18897d06ea88d020a0b", "createdAt"=>1301721480, "type"=>"checkin", "timeZone"=>"America/Chicago",
  #  "venue"=>{"id"=>"4c047ed13f03b713f8275241", "name"=>"Moe's Cantina",
  #  "contact"=>{},
  #  "location"=>
  #   {"address"=>"155 W. Kinzie", "crossStreet"=>"in River North", "city"=>"Chicago", "state"=>"IL",
  #    "postalCode"=>"60654", "lat"=>41.88883, "lng"=>-87.633208},
  #    "categories"=>[
  #     {"id"=>"4bf58dd8d48988d1db931735", "name"=>"Tapas Restaurants", "icon"=>"http://foursquare.com/img/categories/food/default.png", "parents"=>["Food"], "primary"=>true},
  #      {"id"=>"4bf58dd8d48988d1c1941735", "name"=>"Mexican Restaurants", "icon"=>"http://foursquare.com/img/categories/food/default.png", "parents"=>["Food"]},
  #      {"id"=>"4bf58dd8d48988d116941735", "name"=>"Bars", "icon"=>"http://foursquare.com/img/categories/nightlife/default.png", "parents"=>["Nightlife Spots"]}],
  #      "verified"=>false,
  #      "stats"=>{"checkinsCount"=>1691, "usersCount"=>1041}, "todos"=>{"count"=>0}}, "photos"=>{"count"=>0, "items"=>[]},
  #      "comments"=>{"count"=>0, "items"=>[]}}
  # deprecated
  # e.g. {"id"=>141731194, "created"=>"Sun, 22 Aug 10 23:16:33 +0000", "timezone"=>"America/Chicago",
  #       "venue"=>{"id"=>4172889, "name"=>"Zed 451", "address"=>"763 N. Clark St.", "city"=>"Chicago", "state"=>"Illinois",
  #                 "geolat"=>41.8964066, "geolong"=>-87.6312161}
  #      }
  def self.import_checkin(user, checkin_hash)
    # normalize foursquare venue hash and import location
    log("[user:#{user.id}] #{user.handle} importing foursquare checkin #{checkin_hash.inspect}");
    @venue    = checkin_hash['venue']
    @location = @venue['location']
    @hash     = {'name' => @venue['name'], 'address' => @location['address'], 'city' => @location['city'],
                 'state' => @location['state'], 'lat' => @location['lat'], 'lng' => @location['lng']}
    @location = LocationImport.import_location(@venue['id'], Source.foursquare, @hash)
    if @location.blank?
      raise Exception, "invalid location #{checkin_hash}"
    end

    begin
      # create checkin timestamp adjusted for specified timezone
      Time.zone   = ActiveSupport::TimeZone.zones_map[checkin_hash['timeZone']]
      checkin_at  = Time.zone.at(checkin_hash['createdAt']).utc
    rescue Exception => e
      # default to utc
      checkin_at  = Time.at(checkin_hash['createdAt']).utc
    end

    # find/add checkin
    options   = {:location => @location, :checkin_at => checkin_at, :source_id => checkin_hash['id'],
                 :source_type => Source.foursquare}
    @checkin  = user.checkins.find_by_source_id_and_source_type(options[:source_id], options[:source_type])
    if @checkin.blank?
      # add checkin
      @checkin = user.checkins.create(options)
    end
    @checkin
  end

  # import tags for the specific location sources
  def self.import_tags(options={})
    # initialize location sources, using specified ids collection or all
    conditions        = options['location_sources'] ? options['location_sources'] : :all
    location_sources  = LocationSource.foursquare.find(conditions, :include => :location)

    # find random foursquare oauth
    oauth             = Oauth.foursquare.limit(1).order("rand()").first
    
    if oauth.blank?
      log("[foursquare] error, import_tags could not find an oauth key")
      return false
    end

    # foursquare api v2 uses the oauth1 access_token_secret
    client            = FoursquareApi.new(oauth.access_token_secret.present? ? oauth.access_token_secret :
                                          oauth.access_token)

    Array(location_sources).each do |ls|
      # check if we have already imported tags from this source
      next if ls.tagged?

      begin
        response  = client.venues_detail(:vid => ls.source_id)
        code      = response['meta']['code']
        if code != 200
          # foursquare returned an error, raise an exception
          raise Exception, response['meta']
        end
        # parse category tags
        venue       = response['response']['venue']
        categories  = venue['categories']
        tag_list    = category_tag_list(categories)
        # add location tags, duplicate tags are ignored
        location    = ls.location
        location.tag_list.add(tag_list)
        location.save
        # mark location source as tagged
        ls.tagged!
        log("[location:#{location.id}] #{location.name} tagged with:'#{tag_list.join(',')}' from foursquare")
      rescue Exception => e
        log("[location:#{location.try(:id)}] #{location.try(:name)} #{__method__.to_s} #{e.message}", :error)
      end
    end

    true
  end

  # map the specified location(s) to foursquare
  def self.map_location(options={})
    # todo: convert to foursquare api v2
    return 0

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
  # e.g
  # {"id"=>"4bf58dd8d48988d1e0931735", "name"=>"Coffee Shops", "parents"=>["Food"], "primary"=>true
  #  "icon"=>"http://foursquare.com/img/categories/food/coffeeshop.png"}
  # e.g. {"id"=>79048, "fullpathname"=>"Food:Burgers", "nodename"=>"Burgers", "iconurl"=>"http://foursquare.com/img/categories/food/burger.png"}
  def self.category_tag_list(categories)
    tag_list = categories.inject([]) do |array, category_hash|
      array.push(Tagger.normalize(category_hash['name'])) rescue nil
      # ignore parent categories, for now
      # if category_hash['parents'].any?
      #   category_hash['parents'].each { |s| array.push(Tagger.normalize(s)) }
      # end
      array
    end.flatten.uniq.sort
    tag_list
  end
  

end