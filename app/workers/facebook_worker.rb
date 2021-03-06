class FacebookWorker
  # resque queue
  @queue = :normal

  def self.log(s, level = :info)
    AppLogger.log(s, nil, level)
  end

  def self.perform(method, *args)
    self.send(method, *args)
  end

  def self.source
    'facebook'
  end

  # set default date, dating back to before facebook places was release
  def self.default_checkin_since_timestamp
    Time.zone.parse("August 1, 2010").to_s(:datetime_schedule)
  end

  def self.import_checkins(options={})
    # find user oauth object
    user            = User.find_by_id(options['user_id'])
    oauth           = options['oauth_id'] ? Oauth.find_by_id(options['oauth_id']) : Oauth.find_user_oauth(user, source)
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
      # initialize facebook client
      client = FacebookClient.new(oauth.access_token)

      # parse options
      # http://developers.facebook.com/docs/api#paging
      # options - since, until, limit, offset

      log("[user:#{user.id}] #{user.handle} importing #{source} checkins with options:#{options.inspect}, last checked about #{mm} minutes ago")

      # get checkins, handle and log exceptions
      checkins = client.checkins(user.facebook_id, options)
  
      # check error condition
      if checkins['error']
        raise Exception, "facebook error: #{checkins['error']}"
      end

      collection = checkins['data'].inject([]) do |array, checkin_hash|
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
    log("[user:#{user.id}] importing facebook checkin #{checkin_hash.inspect}");
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

  # import facebook friends for the specified user
  def self.import_friends(options={})
    begin
      user  = User.find_by_id(options['user_id'])
      log("[user:#{user.id}] #{user.handle} checking facebook friends")
      # find user oauth object
      oauth = options['oauth_id'] ? Oauth.find_by_id(params['oauth_id']) : Oauth.find_user_oauth(user, source)
      return nil if oauth.blank?
      # initialize facebook client
      facebook  = FacebookClient.new(oauth.access_token)
      friends   = facebook.friends['data'] || []
      log("[user:#{user.id}] #{user.handle} importing facebook friends with checkins")
      friends.each do |friend_hash|
        # check friend limit
        break if user.friends.count >= Friendship.limit
        begin
          friend_name     = friend_hash['name']
          friend_handle   = User.handle_from_full_name(friend_name)
          friend_fbid     = friend_hash['id']
          # check if user already exists
          friend          = User.find_by_facebook_id(friend_fbid)
          if friend
            # user already exists, check friend relationship
            if !(user.friends + user.inverse_friends).include?(friend)
              # add friendship
              user.friendships.create(:friend => friend)
            end
          else
            # check user's checkin data
            friend_checkins = facebook.checkins(friend_fbid, options)['data']
            # skip if friend has no checkins
            next if friend_checkins.try(:size).to_i == 0
            # get basic user data from facebook
            friend_data     = facebook.user(friend_fbid)
            friend_gender   = friend_data.try(:[], 'gender')
            # create friend, friendship
            friend          = User.create!(:handle => friend_handle, :facebook_id => friend_fbid,
                                           :gender => friend_gender)
            user.friendships.create(:friend => friend)
            log("[user:#{user.id}] #{user.handle} imported facebook friend #{friend.handle}:#{friend.id}:facebook:#{friend_fbid}")
          end
        rescue Exception => e
          log("[user:#{user.id}] #{user.handle} #{__method__.to_s} exception: #{e.message}", :error)
        end
      end
      # send event
      Friendship.event_friends_imported(user, source)
    rescue Exception => e
      log("[#{user.handle}] #{__method__.to_s} exception: #{e.message}", :error)
    end
  end

  # import tags for the specific location sources
  def self.import_tags(options={})
    # initialize location sources, using specified ids collection or all
    conditions        = options['location_sources'] ? options['location_sources'] : :all
    location_sources  = LocationSource.facebook.find(conditions, :include => :location)

    location_sources.each do |ls|
      # check if we have already imported tags from this source
      next if ls.tagged_at?

      begin
        # initialize facebook client, no token required
        facebook  = FacebookClient.new(nil)
        place     = facebook.place(ls.source_id)
        location  = ls.location
        log("[location:#{location.id}] #{location.name} ... no tags for facebook locations")
      rescue Exception => e
        log("[location:#{location.id}] #{location.name} #{__method__.to_s} #{e.message}", :error)
      end

      nil
    end
  end

end