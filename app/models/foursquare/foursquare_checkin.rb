class FoursquareCheckin
  
  def self.import_checkins(user, options={})
    # find foursquare oauth tokens
    oauth = user.oauths.where(:name => 'foursquare').first
    if oauth.blank?
      log(:notice, "#{user.handle}: no foursquare oauth token")
      return nil
    end

    # find checkin log
    checkin_log     = user.checkin_logs.find_or_create_by_source('foursquare')
    checkins_start  = user.checkins.count

    # compare last check timestamp vs current timestamp
    last_check_at   = checkin_log.last_check_at || Time.zone.now-1.year
    if (last_check_at + Checkin.minimum_check_interval) > Time.zone.now
      log(:notice, "#{user.handle}: skipping check, last check was at #{last_check_at}")
      return checkin_log
    end

    begin
      log(:ok, "#{user.handle}: importing foursquare checkin history")

      # initiialize oauth object
      foursquare_oauth = Foursquare::OAuth.new(FOURSQUARE_KEY, FOURSQUARE_SECRET)
      foursquare_oauth.authorize_from_access(oauth.access_token, oauth.access_token_secret)
      
      # initialize foursquare client
      foursquare = Foursquare::Base.new(foursquare_oauth)
      if foursquare.test['response'] != 'ok'
        raise Exception, "foursquare ping failed"
      end

      # get checkins
      checkins = foursquare.history
      checkins.each do |checkin_hash|
        import_checkin(user, checkin_hash)
      end
    rescue Exception => e
      log(:error, "#{user.handle}: #{e.message}")
      checkin_log.update_attributes(:state => 'error', :checkins => 0, :last_check_at => Time.zone.now)
    else
      checkins_added = user.checkins.count - checkins_start
      checkin_log.update_attributes(:state => 'success', :checkins => checkins_added, :last_check_at => Time.zone.now)
      log(:ok, "#{user.handle}: imported #{checkins_added} foursquare checkins")
      if checkins_added > 0
        # rebuild sphinx index
        Delayed::Job.enqueue(SphinxJob.new(:index => 'user'), 0)
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
    options  = Hash[:location => @location, :checkin_at => Time.zone.now, :source_id => checkin_hash['id'].to_s, :source_type => Source.foursquare]
    @checkin = user.checkins.find_by_source_id_and_source_type(options[:source_id], options[:source_type])
    log(:ok, "#{user.handle}: added checkin #{@location.name}") if @checkin.blank?
    @checkin ||= user.checkins.create(options)
  end

  def self.log(level, s, options={})
    CHECKINS_LOGGER.debug("#{Time.now}: [#{level}] #{s}")
  end
  
end