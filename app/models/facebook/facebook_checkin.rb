class FacebookCheckin
  
  # import all checkins for the specfied user
  def self.import_checkins(user, options={})
    source = 'facebook'
    # find user
    if user.is_a?(String)
      user = User.find_by_handle(user)
    end
    if user.blank?
      log(:notice, "invalid user #{user.inspect}")
      return nil
    end
    # find facebook oauth tokens
    oauth  = user.oauths.where(:name => source).first
    if oauth.blank?
      log(:notice, "[#{user.handle}] no #{source} oauth token")
      return nil
    end

    # find checkin log
    checkin_log    = user.checkin_logs.find_or_create_by_source(source)
    checkins_start = user.checkins.count

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

      # initialize facebook client
      facebook = FacebookClient.new(oauth.access_token)

      # parse options
      # http://developers.facebook.com/docs/api#paging
      # options - since, until, limit, offset
      if options[:since]
        # get checkins since a timestamp
        case options[:since]
        when :last
          # find last facebok checkin's timestamp
          options[:since] = user.checkins.facebook.recent.limit(1).first.try(:checkin_at).to_s(:datetime_schedule) rescue Time.zone.now.to_s(:datetime)
          log(:ok, "[#{user.handle}] importing since #{options[:since]}")
        end
      end

      # get checkins
      checkins = facebook.checkins(user.facebook_id, options)
      checkins['data'].each do |checkin_hash|
        import_checkin(user, checkin_hash)
      end
    rescue Exception => e
      log(:error, "[#{user.handle}] #{e.message}")
      checkin_log.update_attributes(:state => 'error', :last_check_at => Time.zone.now)
    else
      checkins_added = user.checkins.count - checkins_start
      checkin_log.update_attributes(:state => 'success', :checkins => checkins_added, :last_check_at => Time.zone.now)
      log(:ok, "[#{user.handle}] imported #{checkins_added} #{source} checkins")

      if user.reload.suggestionable?
        # use dj to create suggestions
        SuggestionAlgorithm.send_later(:create_for, user, Hash[:algorithm => [:checkins, :radius, :gender], :limit => 1])
        # SuggestionAlgorithm.delay.create_for(user, Hash[:algorithm => [:checkins, :radius, :gender], :limit => 1])
      end
      
      if user.low_activity_alertable?
        # send low activity alert
        user.send_low_activity_alert
      end

      if checkins_added > 0
        # use dj to rebuild sphinx index
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
    checkin_at  = Time.parse(checkin_hash['created_time']).utc # created_time is in utc format
    options     = Hash[:location => @location, :checkin_at => checkin_at, :source_id => checkin_hash['id'].to_s, :source_type => Source.facebook]
    @checkin    = user.checkins.find_by_source_id_and_source_type(options[:source_id], options[:source_type])
    log(:ok, "[#{user.handle}] added checkin #{@location.name}") if @checkin.blank?
    @checkin    ||= user.checkins.create(options)
  end

  def self.log(level, s, options={})
    CHECKINS_LOGGER.debug("#{Time.now}: [#{level}] #{s}")
    if level == :error
      EXCEPTIONS_LOGGER.debug("#{Time.now}: [#{level}] #{s}")
    end
  end

end