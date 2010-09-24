class FoursquareCheckin
  
  def self.import_checkins(user, options={})
    source = 'foursquare'
    # find foursquare oauth tokens
    oauth  = user.oauths.where(:name => source).first
    if oauth.blank?
      log(:notice, "[#{user.handle}] no #{source} oauth token")
      return nil
    end

    # find checkin log
    checkin_log     = user.checkin_logs.find_or_create_by_source(source)
    checkins_start  = user.checkins.count

    # compare last check timestamp + check interval vs current timestamp
    last_check_at   = checkin_log.last_check_at
    last_check_mins = options[:minutes_since] ? options.delete(:minutes_since).to_i.minutes : Checkin.poll_interval
    
    case
    when last_check_at.blank?
      mm = 0
    when (last_check_at + last_check_mins) > Time.zone.now
      mm, ss = (Time.zone.now-last_check_at).divmod(60)
      log(:ok, "[#{user.handle}] importing #{source} skipped because last check was about #{mm} minutes ago")
      return checkin_log
    else
      mm, ss = (Time.zone.now-last_check_at).divmod(60)
    end

    begin
      log(:ok, "[#{user.handle}] importing #{source} checkin history #{options.inspect}, last checked about #{mm} minutes ago")

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
          log(:ok, "[#{user.handle}] importing sinceid #{options[:sinceid]}")
        end
      end

      # default is 20, max is 250
      if options[:limit]
        options[:l] = options.delete(:limit)
      end

      # get checkins
      checkins = foursquare.history(options)
      checkins.each do |checkin_hash|
        import_checkin(user, checkin_hash)
      end
    rescue Exception => e
      log(:error, "[#{user.handle}] #{e.message}")
      checkin_log.update_attributes(:state => 'error', :checkins => 0, :last_check_at => Time.zone.now)
    else
      checkins_added = user.checkins.count - checkins_start
      checkin_log.update_attributes(:state => 'success', :checkins => checkins_added, :last_check_at => Time.zone.now)
      log(:ok, "[#{user.handle}] imported #{checkins_added} #{source} checkins")

      if checkins_added > 0
        # use dj to rebuild sphinx index
        Delayed::Job.enqueue(SphinxJob.new(:index => 'user'), 0)
      end

      if user.reload.suggestionable?
        # use dj to create suggestions
        SuggestionAlgorithm.send_later(:create_for, user, Hash[:algorithm => [:checkins, :radius_tags, :tags, :gender], :limit => 1])
      else
        # send alert
        user.send_alert(:id => :need_checkins)
      end
    end
    checkin_log
  end
  
  # import a foursquare checkin hash
  # e.g. {"id"=>141731194, "created"=>"Sun, 22 Aug 10 23:16:33 +0000", "timezone"=>"America/Chicago",
  #       "venue"=>{"id"=>4172889, "name"=>"Zed 451", "address"=>"763 N. Clark St.", "city"=>"Chicago", "state"=>"Illinois",
  #                 "geolat"=>41.8964066, "geolong"=>-87.6312161}
  #      }
  def self.import_checkin(user, checkin_hash)
    # map foursquare venue to a location
    @location = LocationImport.import_foursquare_venue(checkin_hash['venue'])
    if @location.blank?
      raise Exception, "invalid location #{checkin_hash['venue']}"
    end
    
    # add checkin
    checkin_at  = Time.parse(checkin_hash['created']).utc # xxx - need to account for 'timezone' attribute
    options     = Hash[:location => @location, :checkin_at => checkin_at, :source_id => checkin_hash['id'].to_s, :source_type => Source.foursquare]
    @checkin    = user.checkins.find_by_source_id_and_source_type(options[:source_id], options[:source_type])
    log(:ok, "[#{user.handle}] added checkin #{@location.name}") if @checkin.blank?
    @checkin    ||= user.checkins.create(options)
  end

  def self.log(level, s, options={})
    CHECKINS_LOGGER.info("#{Time.now}: [#{level}] #{s}")
    if level == :error
      EXCEPTIONS_LOGGER.info("#{Time.now}: [error] #{s}")
    end
  end
  
end