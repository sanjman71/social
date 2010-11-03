module Users::Search
  
  def search_geo_checkins(options={})
    add_geo_params(options)
    search_checkins(options)
  end

  # search users or checkins, filter by matching checkins
  def search_checkins(options={})
    case options[:klass].to_s
    when 'Checkin'
    when 'User'
      # find user location ids
      loc_ids = locations.collect(&:id)
      options.update(:with_location_ids => [loc_ids]) unless options[:with_location_ids]
      options.update(:with_gender => default_gender) unless options[:with_gender]
    end
    # with_my_checkins includes all user checkin data in the search
    unless (options[:without_user_ids] or options[:with_my_checkins])
      options.update(:without_user_ids => [self.id])
    end
    search(options)
  end

  # search users or locations, filter by matching location tags
  def search_tags(options={})
    # find user location tag ids
    tag_ids = locations.collect(&:tag_ids).flatten
    options.update(:with_tag_ids => tag_ids) unless options[:with_tag_ids]
    if options[:with_tag_ids].blank?
      # no tags to search
      return []
    end
    case options[:klass].to_s
    when 'Location'
      # exclude user checkin locations
      loc_ids = locationships.my_checkins.collect(&:location_id)
      options.update(:without_location_ids => [loc_ids])
    when 'User'
      options.update(:with_gender => default_gender) unless options[:with_gender]
      # exclude user
      options.update(:without_user_ids => [self.id]) unless options[:without_user_ids]
    else
      raise Exception, "missing or invalid klass"
    end
    search(options)
  end

  # search users, filter by distance and gender
  def search_geo_gender(options={})
    add_geo_params(options)
    search_gender(options)
  end

  # search users, filter by gender
  def search_gender(options={})
    options.update(:with_gender => default_gender) unless options[:with_gender]
    options.update(:without_user_ids => [self.id]) unless options[:without_user_ids]
    options.update(:klass => User)
    search(options)
  end

  # search users or locations, filter by distance and matching location tags
  def search_geo_tags(options={})
    add_geo_params(options)
    search_tags(options)
  end

  # search users, filter by distance and friends
  def search_geo_friends(options={})
    add_geo_params(options)
    options.update(:klass => User)
    options.update(:without_user_ids => [self.id]) unless options[:without_user_ids]
    options.update(:with_user_ids => (friends+inverse_friends).collect(&:id)) unless options[:with_user_ids]
    search(options)
  end

  # search users or locations, filter by distance and friend checkins
  def search_geo_friend_checkins(options={})
    add_geo_params(options)
    # find friend checkin location ids
    loc_ids = locationships.friend_checkins.collect(&:location_id)
    options.update(:with_location_ids => [loc_ids])
    case options[:klass].to_s
    when 'Location'
    when 'User'
      options.update(:without_user_ids => [self.id]) unless options[:without_user_ids]
    else
      raise Exception, "missing or invalid klass"
    end
    search(options)
  end

  # search users or locations, filter by distance
  def search_geo(options)
    add_geo_params(options)
    case options[:klass].to_s
    when 'Location'
    when 'User'
      options.update(:with_gender => default_gender) unless options[:with_gender]
    end
    options.update(:without_user_ids => [self.id]) unless options[:without_user_ids]
    search(options)
  end

  def add_geo_params(options={})
    # check if geo parameters are already set
    return if !options[:geo_origin].blank? and !options[:geo_distance].blank?
    # allow meters or miles
    if (options[:meters] or options[:miles]) and self.mappable?
      meters = options[:meters] ? options[:meters].to_f : options[:miles].miles.meters.value
      options.update(:geo_origin => [lat.radians, lng.radians], :geo_distance => 0.0..meters)
    end
  end

  def search(options={})
    klass       = options[:klass] ? options[:klass] : User
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
      if options[:with_checkin_ids] # e.g. [1,3,5]
        with.update(:checkin_ids => options[:with_checkin_ids])
      end
      if options[:without_user_ids] # e.g. [1,2,3]
        without.update(:user_ids => options[:without_user_ids])
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

    if options[:order]
      case options[:order]
      when :location_relevance
        sort_order = send("order_#{options[:order].to_s}")
      end
      sort_mode   = :expr
    else
      # default sort
      sort_mode   = :extended
      sort_order  = geo.blank? ? "@relevance DESC" : "@geodist ASC, @relevance DESC"
    end

    args        = Hash[:without => without, :with => with, :conditions => conditions, :match_mode => :extended,
                       :sort_mode => sort_mode, :order => sort_order,
                       :page => page, :per_page => per_page].update(geo)
    objects     = klass.send(method, query, args)
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
          when :location_relevance
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

  def order_location_relevance(options={})
    sort_expr = []
    if (my_checkin_loc_ids = locationships.my_checkins.collect(&:location_id)).any?
      sort_expr.push("5 * IN(location_ids, %s)" % my_checkin_loc_ids.join(','))
    end
    if (planned_loc_ids = locationships.planned_checkins.collect(&:location_id)).any?
      sort_expr.push("3 * IN(location_ids, %s)" % planned_loc_ids.join(','))
    end
    if (tag_ids = locations.collect(&:tag_ids).flatten.uniq.sort).any?
      sort_expr.push("3 * IN(tag_ids, %s)" % tag_ids.join(','))
    end
    sort_expr.join(" + ")
  end

  def default_gender
    return 1 if self.gender == 2
    return 2 if self.gender == 1
    return 0
  end

end