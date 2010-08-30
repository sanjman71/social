class FacebookCheckin
  
  # import all checkins for the specfied user
  def self.import_checkins(user)
    # find foursquare oauth tokens
    oauth = user.oauths.where(:name => 'facebook').first
    if oauth.blank?
      log(:notice, "#{user.handle}: no facebook oauth token")
      return nil
    end

    # find checkin log
    checkin_log    = user.checkin_logs.find_or_create_by_source('facebook')
    checkins_start = user.checkins.count

    # compare last check timestamp vs current timestamp
    last_check_at   = checkin_log.last_check_at || Time.zone.now-1.year
    if (last_check_at + Checkin.minimum_check_interval) > Time.zone.now
      log(:notice, "#{user.handle}: skipping check, last check was at #{last_check_at}")
      return checkin_log
    end
  
    begin
      log(:ok, "#{user.handle}: importing facebook checkin history")

      # initialize facebook client
      facebook = FacebookClient.new(oauth.access_token)

      # get checkins
      checkins = facebook.checkins(user.facebook_id)
      checkins['data'].each do |checkin_hash|
        import_checkin(user, checkin_hash)
      end
    rescue Exception => e
      log(:error, "#{user.handle}: #{e.message}")
      checkin_log.update_attributes(:state => 'error', :last_check_at => Time.zone.now)
    else
      checkins_added = user.checkins.count - checkins_start
      checkin_log.update_attributes(:state => 'success', :checkins => checkins_added, :last_check_at => Time.zone.now)
      log(:ok, "#{user.handle}: imported #{checkins_added} facebook checkins")
      if checkins_added > 0
        # rebuild sphinx index
        Delayed::Job.enqueue(SphinxJob.new(:index => 'user'), 0)
      end
    end

    checkin_log
  end

  # import a facebook checkin hash
  # e.g. {"id"=>141731194, "from"=>{"name"=>"Sanjay Kapoor", "id"=>"633015812"},
  #       "place"=>{"id"=>"117669674925118", "name"=>"Bull & Bear",
  #                 "location"=>{"street"=>"431 N Wells St", "city"=>"Chicago", "state"=>"IL", "zip"=>"60654-4512",
  #                              "latitude"=>41.890177, "longitude"=>-87.633815}},
  #       "application"=>nil, "created_time"=>"2010-08-28T22:33:53+0000"}
  def self.import_checkin(user, checkin_hash)
    # import location
    @location = LocationImport.import_facebook_place(checkin_hash['place'])
    if @location.blank?
      raise Exception, "invalid location #{checkin_hash['place']}"
    end

    # add checkin
    options  = Hash[:location => @location, :checkin_at => Time.zone.now, :source_id => checkin_hash['id'].to_s, :source_type => Source.facebook]
    @checkin = user.checkins.find_by_source_id_and_source_type(options[:source_id], options[:source_type])
    log(:ok, "#{user.handle}: added checkin #{@location.name}") if @checkin.blank?
    @checkin ||= user.checkins.create(options)
  end

  def self.log(level, s, options={})
    CHECKINS_LOGGER.debug("#{Time.now}: [#{level}] #{s}")
  end

end