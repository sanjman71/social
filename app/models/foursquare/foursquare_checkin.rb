class FoursquareCheckin
  
  def self.source
    'foursquare'
  end

  # import checkins for the specified user, usually called asynchronously
  def self.async_import_checkins(user, options={})
    # find user oauth object
    oauth           = options[:oauth_id] ? Oauth.find_by_id(params[:oauth_id]) : Oauth.find_user_oauth(user, source)
    return nil if oauth.blank?

    # find checkin log
    checkin_log     = user.checkin_logs.find_or_create_by_source(source)

    # compare last check timestamp + check interval vs current timestamp
    last_check_at   = checkin_log.last_check_at
    last_check_mins = options[:minutes_since] ? options.delete(:minutes_since).to_i.minutes : Checkin.poll_interval
    
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
      log("[user:#{user.id}] #{user.handle} importing #{source} checkin history #{options.inspect}, last checked about #{mm} minutes ago")

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
      if options[:sinceid]
        # get checkins since id
        case options[:sinceid]
        when :last
          # find last foursquare checkin
          options[:sinceid] = user.checkins.foursquare.recent.limit(1).first.try(:source_id)
          log("[user:#{user.id}] #{user.handle} importing sinceid #{options[:sinceid]}")
        end
      end

      # default is 20, max is 250
      if options[:limit]
        options[:l] = options.delete(:limit)
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

  # show friend checkins
  def self.show_friend_checkins(user, options={})
    # find user oauth object
    oauth = Oauth.find_user_oauth(user, source)
    return nil if oauth.blank?

    begin
      # initiialize oauth object
      foursquare_oauth = Foursquare::OAuth.new(FOURSQUARE_KEY, FOURSQUARE_SECRET)
      foursquare_oauth.authorize_from_access(oauth.access_token, oauth.access_token_secret)
      
      # initialize foursquare client
      foursquare = Foursquare::Base.new(foursquare_oauth)
      if foursquare.test['response'] != 'ok'
        raise Exception, "foursquare ping failed"
      end
      
      # find friend checkins
      checkins = foursquare.checkins
      checkins.each do |checkin_hash|
        # checkin hash keys: 'id', 'created', 'timezone', 'ismayor', 'venue', 'user', 'display', 'ping'
        user_hash  = checkin_hash['user']
        venue_hash = checkin_hash['venue']
        # skip self user
        next if user_hash['id'].to_i == user.foursquare_id.to_i
        user_name  = "#{user_hash['firstname']} #{user_hash['lastname']}"
        venue_name = venue_hash.try(:[], 'name')
        # puts "#{Time.now}: user #{user_name}, venue: #{venue_name}, at: #{checkin_hash['created']}"
      end
    rescue Exception => e
      log("[user:#{user.id}] #{user.handle} #{__method__.to_s} #{e.message}", :error)
    else
    end
  end

  def self.log(s, level = :info)
    Checkin.log(s, level)
  end

end