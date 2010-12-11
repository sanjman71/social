module Users::Search

  def search_all_checkins(options={})
    add_geo_params(options)
    # include my checkins and friend checkins
    search_checkins(options)
  end

  alias :search_outlately_checkins :search_all_checkins

  def search_my_checkins(options={})
    add_geo_params(options)
    # include my checkins
    options.update(:with_user_ids => [self.id]) unless options[:with_user_ids]
    search_checkins(options)
  end
  
  def search_others_checkins(options={})
    add_geo_params(options)
    # exclude my checkins
    options.update(:without_user_ids => [self.id]) unless options[:without_user_ids]
    search_checkins(options)
  end

  def search_friends_checkins(options={})
    add_geo_params(options)
    # include only friend checkins
    unless options[:with_user_ids]
      friend_ids = (friends+inverse_friends).collect(&:id)
      return [] if friend_ids.blank?
      options.update(:with_user_ids => friend_ids)
    end
    search_checkins(options)
  end

  def search_gals_checkins(options={})
    add_geo_params(options)
    # exclude my checkins
    options.update(:without_user_ids => [self.id]) unless options[:without_user_ids]
    # filter checkins by females
    options.update(:with_gender => [1]) unless options[:with_gender]
    search_checkins(options)
  end

  alias :search_ladies_checkins :search_gals_checkins

  def search_guys_checkins(options={})
    add_geo_params(options)
    # exclude my checkins
    options.update(:without_user_ids => [self.id]) unless options[:without_user_ids]
    # filter checkins by males
    options.update(:with_gender => [2]) unless options[:with_gender]
    search_checkins(options)
  end

  alias :search_men_checkins :search_guys_checkins

  def search_daters_checkins(options={})
    add_geo_params(options)
    # exclude my checkins
    options.update(:without_user_ids => [self.id]) unless options[:without_user_ids]
    # filter checkins by my gender orientation
    options.update(:with_gender => my_gender_orientation) unless options[:with_gender]
    search_checkins(options)
  end

  def search_today_checkins(options={})
    add_geo_params(options)
    # search based on checkin timestamp, which sphinx stores in utc format
    options.update(:with_checkin_at => (Time.zone.now-1.day).to_i..(Time.zone.now+1.minute).utc.to_i)
    # include checkin users marked as available now
    search_checkins(options)
  end

  def search_trending_checkins(options={})
    add_geo_params(options)
    # weight checkins by timestamp
    options[:order] ||= []
    options[:order].push(:sort_trending_checkins).uniq!
    # include checkin users marked as available now
    search_checkins(options)
  end

  # search checkins
  def search_checkins(options={})
    options.update(:klass => Checkin)
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
    options.update(:without_user_ids => [self.id] + friend_ids) unless options[:without_user_ids]
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
    options.update(:with_user_ids => friend_ids) unless options[:with_user_ids]
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
    options.update(:with_user_ids => friend_ids) unless options[:with_user_ids]
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
    page        = options[:page] ? options[:page].to_i : 1
    per_page    = options[:limit] ? options[:limit] : 20
    method      = :search
    query       = options[:query] ? options[:query] : nil
    with        = Hash[]
    without     = Hash[]
    conditions  = Hash[]
    geo         = Hash[]

    # parse klass agnostic options
    if options[:with_location_ids] # e.g. [1,3,5]
      with.update(:location_ids => options[:with_location_ids])
    end
    if options[:without_location_ids] # e.g. [1,3,5]
      without.update(:location_ids => options[:without_location_ids])
    end
    if options[:with_now] # e.g. 0, 1
      with.update(:now => options[:with_now])
    end
    if options[:with_tag_ids] # e.g. [1,3,5]
      with.update(:tag_ids => options[:with_tag_ids])
    end
    if options[:without_tag_ids] # e.g. [1,3,5]
      without.update(:tag_ids => options[:without_tag_ids])
    end
    if options[:with_user_ids] # e.g. [1,2,5]
      with.update(:user_ids => options[:with_user_ids])
    end
    if options[:without_user_ids] # e.g. [1,2,3]
      without.update(:user_ids => options[:without_user_ids])
    end

    case klass.to_s
    when 'Checkin'
      # parse checkin specific options
      if options[:with_checkin_at] # e.g. 1290826420..1290829246 (timestamp converted to ints)
        with.update(:checkin_at => options[:with_checkin_at])
      end
      if options[:with_checkin_ids] # e.g. [1,3,5]
        with.update(:checkin_ids => options[:with_checkin_ids])
      end
      if options[:without_checkin_ids] # e.g. [1,3,5]
        without.update(:checkin_ids => options[:without_checkin_ids])
      end
      if options[:with_gender] # e.g. 1, [1]
        with.update(:gender => Array(options[:with_gender]))
      end
    when 'Location'
    when 'User'
      # parse user specific options
      if options[:with_gender] # e.g. 1, [1]
        with.update(:gender => Array(options[:with_gender]))
      end
    end

    if options[:geo_origin] and options[:geo_distance]
      geo[:geo]         = options[:geo_origin]    # e.g. [lat, lng] (in radians)
      with['@geodist']  = options[:geo_distance]  # e.g. 0.0..5000.0 (in meters, must be floats)
    end

    # check sort order(s)
    sort_orders = Array(options[:order])
    if sort_orders.any?
      # build sort expressions
      sort_exprs = sort_orders.collect do |order|
        # order can be symbol, array or hash
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
          when :sort_trending_checkins
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
    group = Hash[]
    if options[:group]
      case options[:group].to_s
      when 'user'
        group[:group_by]        = 'user_ids'
        group[:group_function]  = :attr
        group[:group_clause]    = sort_mode == :expr ? '@expr desc' : '@relevance DESC'
      end
    end

    args    = Hash[:without => without, :with => with, :conditions => conditions, :match_mode => :extended,
                   :sort_mode => sort_mode, :order => sort_order,
                   :page => page, :per_page => per_page].update(geo).update(group)
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

  # sort trending checkins by timestamp
  def sort_trending_checkins(options={})
    dtime1    = 1.day.ago.utc.to_i
    dtime2    = 2.days.ago.utc.to_i
    dtime3    = 3.days.ago.utc.to_i
    sort_expr = "IF(checkin_at > #{dtime1}, 10.0, IF(checkin_at > #{dtime2}, 5.0, IF(checkin_at > #{dtime3}, 2.0, 1.0)))"
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