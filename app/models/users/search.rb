module Users::Search

  #
  # search search_data_streams
  #

  def search_everyone_data_streams(options={})
    # include members and non-members
    search_data_streams(options)
  end

  def search_ladies_data_streams(options={})
    # filter checkins by females
    options.update(:with_gender => [1]) unless options[:with_gender]
    # exclude checkins by me and my friends
    options.update(:without_user_ids => [self.id] + friend_set) unless options[:without_user_ids]
    search_data_streams(options)
  end

  def search_men_data_streams(options={})
    # filter checkins by males
    options.update(:with_gender => [2]) unless options[:with_gender]
    # exclude checkins by me and my friends
    options.update(:without_user_ids => [self.id] + friend_set) unless options[:without_user_ids]
    search_data_streams(options)
  end

  def search_friends_data_streams(options={})
    # include only friend checkins
    unless options[:with_user_ids]
      return [] if friend_set.blank?
      options.update(:with_user_ids => friend_set)
    end
    search_data_streams(options)
  end

  def search_data_streams(options={})
    add_geo_params(options)
    options.update(:klass => [Checkin, PlannedCheckin, Shout]) unless options[:klass]
    search(options)
  end

  #
  # search checkins
  #

  def search_all_checkins(options={})
    # include members and non-members
    # include my checkins and friend checkins
    search_checkins(options)
  end

  alias :search_everyone_checkins :search_all_checkins

  def search_member_checkins(options={})
    # members only
    options.update(:with_member => 1) unless options[:with_member]
    # include my checkins and friend checkins
    search_checkins(options)
  end

  def search_my_checkins(options={})
    # include my checkins
    options.update(:with_user_ids => [self.id]) unless options[:with_user_ids]
    search_checkins(options)
  end
  
  def search_others_checkins(options={})
    # exclude my checkins
    options.update(:without_user_ids => [self.id]) unless options[:without_user_ids]
    search_checkins(options)
  end

  def search_friends_checkins(options={})
    # include only friend checkins
    unless options[:with_user_ids]
      return [] if friend_set.blank?
      options.update(:with_user_ids => friend_set)
    end
    search_checkins(options)
  end

  def search_gals_checkins(options={})
    # filter checkins by females
    options.update(:with_gender => [1]) unless options[:with_gender]
    search_daters_checkins(options)
  end

  alias :search_ladies_checkins :search_gals_checkins

  def search_guys_checkins(options={})
    # filter checkins by males
    options.update(:with_gender => [2]) unless options[:with_gender]
    search_daters_checkins(options)
  end

  alias :search_men_checkins :search_guys_checkins

  def search_daters_checkins(options={})
    # exclude checkins by me and my friends
    options.update(:without_user_ids => [self.id] + friend_set) unless options[:without_user_ids]
    # filter checkins by my gender orientation
    options.update(:with_gender => my_gender_orientation) unless options[:with_gender]
    search_checkins(options)
  end

  def search_today_checkins(options={})
    # search checkins based on timestamp (which sphinx stores in utc format)
    options.update(:with_checkin_at => (Time.zone.now-1.day).to_i..(Time.zone.now+1.minute).utc.to_i)
    # include checkin users marked as available now
    search_checkins(options)
  end

  # def search_trending_checkins(options={})
  #   # weight checkins by timestamp
  #   options[:order] ||= []
  #   options[:order].push(:sort_trending_checkins).uniq!
  #   # include checkin users marked as available now
  #   search_checkins(options)
  # end

  def search_checkins(options={})
    add_geo_params(options)
    options.update(:klass => Checkin) unless options[:klass]
    search(options)
  end

  #
  # search todos
  #

  def search_all_todos(options={})
    search_todos(options)
  end

  alias :search_everyone_todos :search_all_todos

  def search_ladies_todos(options={})
    # filter todos by females
    options.update(:with_gender => [1]) unless options[:with_gender]
    search_todos(options)
  end

  def search_men_todos(options={})
    # filter todos by males
    options.update(:with_gender => [2]) unless options[:with_gender]
    search_todos(options)
  end

  def search_friends_todos(options={})
    # filter todos by friends
    unless options[:with_user_ids]
      return [] if friend_set.blank?
      options.update(:with_user_ids => friend_set)
    end
    search_todos(options)
  end

  def search_todos(options={})
    add_geo_params(options)
    options.update(:klass => PlannedCheckin) unless options[:klass]
    search(options)
  end

  # search daters by common checkin locations and gender orientation
  def search_daters_by_checkins(options={})
    options.update(:klass => User)
    add_geo_params(options)
    # filter by common locations
    loc_ids = locations.collect(&:id)
    options.update(:with_location_ids => [loc_ids]) unless options[:with_location_ids]
    # filter users by my gender orientation
    options.update(:with_gender => my_gender_orientation) unless options[:with_gender]
    # exclude user and friends
    options.update(:without_user_ids => [self.id] + friend_set) unless options[:without_user_ids]
    search(options)
  end

  # search friends by common checkin locations
  def search_friends_by_checkins(options={})
    options.update(:klass => User)
    add_geo_params(options)
    # filter by common friend locations
    loc_ids = locationships.friend_checkins.collect(&:location_id)
    options.update(:with_location_ids => [loc_ids]) unless options[:with_location_ids]
    # filter by common friends
    options.update(:with_user_ids => friend_set) unless options[:with_user_ids]
    # exclude user
    options.update(:without_user_ids => [self.id]) unless options[:without_user_ids]
    search(options)
  end

  # search users by common checkin locations
  def search_users_by_checkins(options={})
    options.update(:klass => User)
    add_geo_params(options)
    # filter by common locations
    loc_ids = locations.collect(&:id)
    options.update(:with_location_ids => [loc_ids]) unless options[:with_location_ids]
    # exclude user
    options.update(:without_user_ids => [self.id]) unless options[:without_user_ids]
    search(options)
  end

  # search daters by common tags
  def search_daters_by_tags(options={})
    # filter users by my gender orientation
    options.update(:with_gender => my_gender_orientation) unless options[:with_gender]
    search_users_by_tags(options)
  end

  # search users by common tags
  def search_users_by_tags(options={})
    options.update(:klass => User)
    add_geo_params(options)
    unless options[:with_tag_ids]
      # filter by user tag ids
      # check if there are any user tags to search
      return [] if tag_ids.blank?
      options.update(:with_tag_ids => tag_ids)
    end
    # exclude user
    options.update(:without_user_ids => [self.id]) unless options[:without_user_ids]
    search(options)
  end

  # search users, filter by friends and optional distance
  def search_friends(options={})
    add_geo_params(options)
    options.update(:klass => User)
    options.update(:without_user_ids => [self.id]) unless options[:without_user_ids]
    options.update(:with_user_ids => friend_set) unless options[:with_user_ids]
    search(options)
  end

  # search daters, filter by optional distance
  def search_daters(options={})
    options.update(:with_gender => my_gender_orientation) unless options[:with_gender]
    search_users(options)
  end

  # search users, filter by optional distance
  def search_users(options={})
    add_geo_params(options)
    options.update(:klass => User)
    options.update(:without_user_ids => [self.id]) unless options[:without_user_ids]
    search(options)
  end

  # search users, filter by gender and optional distance
  def search_gender(options={})
    add_geo_params(options)
    options.update(:with_gender => my_gender_orientation) unless options[:with_gender]
    options.update(:without_user_ids => [self.id]) unless options[:without_user_ids]
    options.update(:klass => User)
    search(options)
  end

  # search locations, filter by matching location tags and optional distance
  def search_locations_by_tags(options={})
    options.update(:klass => Location)
    add_geo_params(options)
    unless options[:with_tag_ids]
      # filter by user location tag ids
      tag_ids = locations.collect(&:tag_ids).flatten
      # check if there are any tags to search
      return [] if tag_ids.blank?
      options.update(:with_tag_ids => tag_ids)
    end
    # exclude user checkin locations
    loc_ids = locationships.my_checkins.collect(&:location_id)
    options.update(:without_location_ids => [loc_ids])
    search(options)
  end

  # search locations, filter by optional distance
  def search_locations(options={})
    add_geo_params(options)
    options.update(:klass => Location)
    options.update(:without_user_ids => [self.id]) unless options[:without_user_ids]
    search(options)
  end

  def add_geo_params(options={})
    # do nothing if geo parameters are already set
    return if !options[:geo_origin].blank? and !options[:geo_distance].blank?
    # allow meters or miles
    if (options[:meters] or options[:miles]) and mappable?
      # set geo distance
      meters = options[:meters] ? options[:meters].to_f : options[:miles].miles.meters.value
      options.update(:geo_distance => 0.0..meters)
      unless options[:geo_origin]
        # set geo origin to user's lat, lng
        options.update(:geo_origin => [lat.radians, lng.radians])
      end
    end
  end

  def search(options={})
    klass       = options[:klass]
    raise Exception, 'missing klass' if klass.blank?
    if klass.is_a?(Array)
      # use ThinkingSphinx for a multi-model search with classes param
      classes   = klass
      klass     = ThinkingSphinx
    end
    page        = options[:page] ? options[:page].to_i : 1
    per_page    = options[:limit] ? options[:limit] : 20
    method      = :search
    query       = options[:query] ? options[:query] : nil
    with        = {}
    without     = {}
    conditions  = {}
    geo         = {}
    geo_attrs   = {:latitude_attr=>"lat", :longitude_attr=>"lng"}

    # parse klass agnostic options
    if options[:with_gender] # e.g. 1, [1]
      with.update(:gender => Array(options[:with_gender]))
    end
    if options[:with_location_ids] && options[:with_location_ids].any? # e.g. [1,3,5]
      with.update(:location_ids => options[:with_location_ids])
    end
    if options[:without_location_ids] && options[:without_location_ids].any? # e.g. [1,3,5]
      without.update(:location_ids => options[:without_location_ids])
    end
    if options[:with_member] # e.g. 0, 1
      with.update(:member => options[:with_member])
    end
    if options[:with_now] # e.g. 0, 1
      with.update(:now => options[:with_now])
    end
    if options[:with_tag_ids] && options[:with_tag_ids].any? # e.g. [1,3,5]
      with.update(:tag_ids => options[:with_tag_ids])
    end
    if options[:without_tag_ids] && options[:without_tag_ids].any? # e.g. [1,3,5]
      without.update(:tag_ids => options[:without_tag_ids])
    end
    if options[:with_user_ids] && options[:with_user_ids].any? # e.g. [1,2,5]
      with.update(:user_ids => options[:with_user_ids])
    end
    if options[:without_user_ids] && options[:without_user_ids].any? # e.g. [1,2,3]
      without.update(:user_ids => options[:without_user_ids])
    end

    # timestamp_at - applies to all objects
    if options[:with_timestamp_at] # e.g. 1290826420..1290829246 (timestamp converted to int)
      with.update(:timestamp_at => options[:with_timestamp_at])
    end

    # checkins
    if options[:with_checkin_at] # e.g. 1290826420..1290829246 (timestamp converted to int)
      with.update(:checkin_at => options[:with_checkin_at])
    end
    if options[:with_checkin_ids] && options[:with_checkin_ids].any? # e.g. [1,3,5]
      with.update(:checkin_ids => options[:with_checkin_ids])
    end
    if options[:without_checkin_ids] && options[:without_checkin_ids].any? # e.g. [1,3,5]
      without.update(:checkin_ids => options[:without_checkin_ids])
    end

    # todos
    if options[:with_todo_ids] && options[:with_todo_ids].any? # e.g. [1,3,5]
      with.update(:todo_ids => options[:with_todo_ids])
    end
    if options[:without_todo_ids] && options[:without_todo_ids].any? # e.g. [1,3,5]
      without.update(:todo_ids => options[:without_todo_ids])
    end

    # geo
    if options[:geo_origin] and options[:geo_distance]
      geo[:geo]         = options[:geo_origin]    # e.g. [lat, lng] (in radians)
      with['@geodist']  = options[:geo_distance]  # e.g. 0.0..5000.0 (in meters, must be floats)
    end

    # check sort order(s)
    sort_orders = Array(options[:order])
    if sort_orders.any?
      # build sort expressions
      sort_exprs = sort_orders.collect do |order|
        # order can be array, hash, or symbol
        if order.is_a?(Array)
          case order[0]
          when :sort_weight_users, :sort_unweight_users
            # e.g. [:sort_weight_users, [1,3,7]]
            # e.g. [:sort_unweight_users, [1,3,7]]
            send(order[0].to_s, order[1])
          end
        elsif order.is_a?(Hash)
          # collect result of last key, value as sort expr
          expr = nil
          order.each_pair do |key, value|
            case key
            when :sort_weight_users, :sort_unweight_users
              # e.g. {:sort_weight_users, [1,3,7]}
              # e.g. {:sort_unweight_users, [1,3,7]}
              expr = send(key, value)
            end
          end
          expr
        else
          # order is a symbol
          case order
          when :sort_closer_locations
            send(order.to_s)
          when :sort_similar_locations
            send(order.to_s)
          when :sort_other_checkins
            send(order.to_s)
          when :sort_females, :sort_males
            send(order.to_s)
          when :sort_members
            send(order.to_s)
          when /^sort.*_at$/
            send(order.to_s)
          when :sort_checkins_past_day
            send(order.to_s)
          when :sort_random
            ["@random"]
          else
            nil
          end
        end
      end.compact
      if sort_exprs.any?
        sort_mode   = :expr
        sort_order  = sort_exprs.join(' * ')
        # force extended mode for random ordering
        sort_mode   = :extended if sort_order.match(/@random/)
      else
        # default sort
        sort_mode   = :extended
        sort_order  = geo.blank? ? "@relevance DESC" : "@geodist ASC, @relevance DESC"
      end
    else
      # default sort
      sort_mode   = :extended
      sort_order  = geo.blank? ? "@relevance DESC" : "@geodist ASC, @relevance DESC"
    end

    # check grouping(s)
    group = {}
    if options[:group]
      case options[:group].to_s
      when 'user'
        group[:group_by]        = 'user_ids'
        group[:group_function]  = :attr
        group[:group_clause]    = sort_mode == :expr ? '@expr desc' : '@relevance DESC'
      end
    end

    args    = Hash[:without => without, :with => with, :conditions => conditions,
                   :match_mode => :extended, :sort_mode => sort_mode, :order => sort_order,
                   :page => page, :per_page => per_page].update(geo).update(group)
    if geo.present?
      # specify lat,lng attributes required for multi-model search
      args.merge!(geo_attrs)
    end
    if klass == ThinkingSphinx
      # add classes for multi-model search
      args[:classes] = classes
    end
    objects = klass.send(method, query, args)
    begin
      objects.results # query sphinx and populate results
      objects.each do |o|
        self.class.set_match_data(o, options[:order])
      end
      objects
    rescue Exception => e
      []
    end
  end

  # class methods
  def self.included(base)
    def base.set_match_data(object, order)
      if object.respond_to?(:matchby)
        object.matchby = matchby(object, order)
      end
      if object.respond_to?(:matchvalue)
        object.matchvalue = object.sphinx_attributes.try(:[], '@expr') || 0.0
      end
    end

    # return the object's matchby value based on search parameters and result values
    def base.matchby(object, order, default = :filter)
      begin
        case object.sphinx_attributes['@expr']
        when 5.0..100.0
          :location
        when 3.0..5.0
          case order
          when :sort_similar_locations
            :tag
          else
            default
          end
        else
          if object.sphinx_attributes['@geodist']
            :geo_filter
          else
            default
          end
        end
      rescue Exception => e
        default
      end
    end
  end
  
  # weight locations by distance
  def sort_closer_locations(options={})
    distance1 = 25.miles.meters
    distance2 = 50.miles.meters
    distance3 = 100.miles.meters
    sort_expr = "IF(@geodist < #{distance1}, 10.0, IF(@geodist<#{distance2}, 5.0, IF(@geodist<#{distance3}, 1.0, 0.1)))"
    [sort_expr]
  end

  # weight locations by:
  # 1. user checkins at
  # 2. user plans at
  # 3. location tags for user checkins
  def sort_similar_locations(options={})
    sort_expr = []
    if (my_checkin_loc_ids = locationships.my_checkins.collect(&:location_id)).any?
      sort_expr.push("IF(IN(location_ids, %s), 5.0, 1.0)" % my_checkin_loc_ids.join(','))
    end
    if (todo_loc_ids = locationships.todo_checkins.collect(&:location_id)).any?
      sort_expr.push("3.0 * IF(IN(location_ids, %s), 3.0, 1.0)" % todo_loc_ids.join(','))
    end
    # deprecated: no sorting by location tags for now
    # if (tag_ids = locations.collect(&:tag_ids).flatten.uniq.sort).any?
    #   sort_expr.push("3.0 * IF(IN(tag_ids, %s), 3.0, 1.0)" % tag_ids.join(','))
    # end
    sort_expr.any? ? sort_expr : nil
  end

  # negatively weight user checkins
  def sort_other_checkins(options={})
    sort_expr = []
    if (my_checkin_ids = checkins.collect(&:id)).any?
      sort_expr.push("IF(IN(checkin_ids, %s), 0.1, 1.0)" % my_checkin_ids.join(','))
    end
    sort_expr.any? ? sort_expr : nil
  end

  # sort checkins by timestamp
  # def sort_trending_checkins(options={})
  #   dtime1    = 1.day.ago.utc.to_i
  #   dtime2    = 2.days.ago.utc.to_i
  #   dtime3    = 3.days.ago.utc.to_i
  #   sort_expr = "IF(checkin_at > #{dtime1}, 10.0, IF(checkin_at > #{dtime2}, 5.0, IF(checkin_at > #{dtime3}, 2.0, 1.0)))"
  #   [sort_expr]
  # end

  # sort checkins by utc timestamps, rank last day's checkins higher than older checkins
  def sort_checkins_past_day(options={})
    dtime1    = 1.day.ago.utc.to_i
    sort_expr = "IF(checkin_at > #{dtime1}, 10.0, 1.0)"
    [sort_expr]
  end

  # sort checkins by utc timestamp, rank last week's checkins higher than older checkins
  # def sort_checkins_past_week(options={})
  #   dtime1    = 1.day.ago.utc.to_i
  #   dtime2    = 2.days.ago.utc.to_i
  #   dtime3    = 5.days.ago.utc.to_i
  #   dtime4    = 7.days.ago.utc.to_i
  #   sort_expr = "IF(checkin_at > #{dtime1}, 10.0, IF(checkin_at > #{dtime2}, 9.0,
  #                IF(checkin_at > #{dtime3}, 7.0, IF(checkin_at > #{dtime4}, 5.0, 1.0))))"
  #   [sort_expr]
  # end

  # sort objects by utc timestamp_at, upcoming then recent
  def sort_coming_recent_timestamp_at(options={})
    dtime1    = 2.days.from_now.utc.to_i
    dtime2    = 1.day.from_now.utc.to_i
    dtime3    = Time.now.utc.to_i
    dtime4    = 1.day.ago.utc.to_i
    dtime5    = 7.days.ago.utc.to_i
    dtime6    = 14.days.ago.utc.to_i
    dtime7    = 30.days.ago.utc.to_i
    sort_expr = "IF(timestamp_at > #{dtime1}, 7.0, IF(timestamp_at > #{dtime2}, 9.0,
                 IF(timestamp_at > #{dtime3}, 11.0, IF(timestamp_at > #{dtime4}, 5.0,
                 IF(timestamp_at > #{dtime5}, 3.0, IF(timestamp_at > #{dtime6}, 2.5,
                 IF(timestamp_at > #{dtime7}, 2.0, 1.0)))))))"
    [sort_expr]
  end

  # sort objects by utc timestamp_at, most recent first
  def sort_recent_timestamp_at(options={})
    dtime1    = 1.day.ago.utc.to_i
    dtime2    = 7.days.ago.utc.to_i
    dtime3    = 14.days.ago.utc.to_i
    dtime4    = 30.days.ago.utc.to_i
    sort_expr = "IF(timestamp_at > #{dtime1}, 10.0, IF(timestamp_at > #{dtime2}, 9.0,
                 IF(timestamp_at > #{dtime3}, 7.0, IF(timestamp_at > #{dtime4}, 5.0, 1.0))))"
    [sort_expr]
  end

  def sort_females(options={})
    sort_expr = "IF(gender = 1, 5.0, 1.0)"
    [sort_expr]
  end

  def sort_males(options={})
    sort_expr = "IF(gender = 2, 5.0, 1.0)"
    [sort_expr]
  end

  def sort_members(options={})
    sort_expr = "IF(member = 1, 1.0, 0.5)"
    [sort_expr]
  end

  def sort_weight_users(user_ids)
    sort_expr = []
    if user_ids.any?
      sort_expr.push("IF(IN(user_ids, %s), 1.5, 1.0)" % user_ids.join(','))
    end
    sort_expr.any? ? sort_expr : nil
  end

  def sort_unweight_users(user_ids)
    sort_expr = []
    if user_ids.any?
      sort_expr.push("IF(IN(user_ids, %s), 0.5, 1.0)" % user_ids.join(','))
    end
    sort_expr.any? ? sort_expr : nil
  end

  def my_gender_orientation
    return 1 if self.gender == 2
    return 2 if self.gender == 1
    return 0
  end

end