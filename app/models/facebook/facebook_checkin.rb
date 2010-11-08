class FacebookCheckin

  def self.source
    'facebook'
  end

  # set default date, dating back to before facebook places was release
  def self.default_checkin_since_timestamp
    Time.zone.parse("August 1, 2010").to_s(:datetime_schedule)
  end

  # import all checkins for the specfied user, usually called asynchronously
  def self.async_import_checkins(user, options={})
    # find user oauth object
    oauth           = options[:oauth_id] ? Oauth.find_by_id(options[:oauth_id]) : Oauth.find_user_oauth(user, source)
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
          options[:since] = user.checkins.facebook.recent.limit(1).first.try(:checkin_at).to_s(:datetime_schedule) rescue default_checkin_since_timestamp
          log("[user:#{user.id}] #{user.handle} importing since #{options[:since]}")
        end
      end

      # get checkins, handle and log exceptions
      checkins    = facebook.checkins(user.facebook_id, options)
      
      # check error condition
      if checkins['error']
        raise Exception, "facebook error: #{checkins['error']}"
      end

      collection  = checkins['data'].inject([]) do |array, checkin_hash|
        begin
          array.push(import_checkin(user, checkin_hash))
        rescue Exception => e
          log("[user:#{user.id}] #{user.handle} #{__method__.to_s} #{e.message}", :error)
        end
        array
      end.compact
    rescue Exception => e
      log("[user:#{user.id}] #{user.handle} #{__method__.to_s} #{e.message}", :error)
      checkin_log.update_attributes(:state => 'error', :last_check_at => Time.zone.now)
    else
      checkin_log.update_attributes(:state => 'success', :checkins => collection.size, :last_check_at => Time.zone.now)
      # after import event
      Checkin.event_checkins_imported(user, collection, source)
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
    # normalize facebook place hash and import location
    @place    = checkin_hash['place']
    @hash     = Hash['name' => @place['name'], 'address' => @place['location']['street'],
                     'city' => @place['location']['city'], 'state' => @place['location']['state'],
                     'zip' => @place['location']['zip'],
                     'lat' => @place['location']['latitude'], 'lng' => @place['location']['longitude']]
    @location = LocationImport.import_location(@place['id'].to_s, Source.facebook, @hash)
    if @location.blank?
      raise Exception, "invalid location #{checkin_hash}"
    end

    # add checkin
    checkin_at  = Time.parse(checkin_hash['created_time']).utc # created_time is in utc format
    options     = Hash[:location => @location, :checkin_at => checkin_at, :source_id => checkin_hash['id'].to_s, :source_type => Source.facebook]
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
      # log(:ok, "[#{user.handle}] importing #{source} friends checkin history #{options.inspect}, last checked about #{mm} minutes ago")

      # initialize facebook client
      facebook = FacebookClient.new(oauth.access_token)

      # get checkins, handle and log exceptions
      checkins = facebook.search_checkins(user.facebook_id, options)
      checkins.each do |checkin|
        puts checkin.inspect
      end
    rescue Exception => e
      log("[user:#{user.id}] #{user.handle} #{__method__.to_s}: #{e.message}", :error)
    end
  end

  def self.log(s, level = :info)
    Checkin.log(s, level)
  end

end