module Users::Search

  def search_all_checkins(options={})
    add_geo_params(options)
    # include my checkins and friend checkins
    search_checkins(options)
  end

  def search_my_checkins(options={})
    add_geo_params(options)
    # include my checkins
    options.update(:with_user_ids => [self.id]) unless options[:with_user_ids]
    search_checkins(options)
  end
  
  def search_other_checkins(options={})
    add_geo_params(options)
    # exclude my checkins
    options.update(:without_user_ids => [self.id]) unless options[:without_user_ids]
    search_checkins(options)
  end

  alias :search_others_checkins :search_other_checkins

  def search_friend_checkins(options={})
    add_geo_params(options)
    # include only friend checkins
    unless options[:with_user_ids]
      friend_ids = (friends+inverse_friends).collect(&:id)
      return [] if friend_ids.blank?
      options.update(:with_user_ids => friend_ids)
    end
    search_checkins(options)
  end

  alias :search_friends_checkins :search_friend_checkins

  def search_dater_checkins(options={})
    add_geo_params(options)
    # exclude my checkins
    options.update(:without_user_ids => [self.id]) unless options[:without_user_ids]
    # filter checkins by my gender orientation
    options.update(:with_gender => my_gender_orientation) unless options[:with_gender]
    search_checkins(options)
  end

  alias :search_daters_checkins :search_dater_checkins

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
    # exclude user
    options.update(:without_user_ids => [self.id]) unless options[:without_user_ids]
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
    options.update(:with_user_ids => (friends+inverse_friends).collect(&:id)) unless options[:with_user_ids]
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

  def search_daters_by_tags(options={})
    # filter users by my gender orientation
    options.update(:with_gender => my_gender_orientation) unless options[:with_gender]
    search_users_by_tags(options)
  end

  def search_users_by_tags(options={})
    options.update(:klass => User)
    add_geo_params(options)
    unless options[:with_tag_ids]
      # filter by user location tag ids
      tag_ids = locations.collect(&:tag_ids).flatten
      # check if there are any tags to search
      return [] if tag_ids.blank?
      options.update(:with_tag_ids => tag_ids)
    end
    # exclude user
    options.update(:without_user_ids => [self.id]) unless options[:without_user_ids]
  end

  # search users, filter by friends and optional distance
  def search_friends(options={})
    add_geo_params(options)
    options.update(:klass => User)
    options.update(:without_user_ids => [self.id]) unless options[:without_user_ids]
    options.update(:with_user_ids => (friends+inverse_friends).collect(&:id)) unless options[:with_user_ids]
    search(options)
  end

  # search users, filter by optional distance
  def search_users(options={})
    add_geo_params(options)
    options.update(:klass => User)
    options.update(:with_gender => my_gender_orientation) unless options[:with_gender]
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

  # search locations, filter by optional distance
  def search_locations(options={})
    add_geo_params(options)
    options.update(:klass => Location)
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

    sort_orders = Array(options[:order])
    if sort_orders.any?
      # build sort expressions
      sort_exprs = sort_orders.collect do |order|
        case order
        when :sort_closer_locations
          send(order.to_s)
        when :sort_similar_locations
          send(order.to_s)
        when :sort_other_checkins
          send(order.to_s)
        else
          nil
        end
      end.compact
      sort_order  = sort_exprs.join(' + ')
      sort_mode   = :expr
    else
      # default sort
      sort_mode   = :extended
      sort_order  = geo.blank? ? "@relevance DESC" : "@geodist ASC, @relevance DESC"
    end

    args    = Hash[:without => without, :with => with, :conditions => conditions, :match_mode => :extended,
                   :sort_mode => sort_mode, :order => sort_order,
                   :page => page, :per_page => per_page].update(geo)
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
    distance1 = 100.miles.meters
    sort_expr = "IF(@geodist < #{distance1}, 10.0, 0.0)"
    [sort_expr]
  end

  # weight locations by:
  # 1. user checkins at
  # 2. user plans at
  # 3. location tags for checkins
  def sort_similar_locations(options={})
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
    sort_expr
  end

  # negatively weight user checkins
  def sort_other_checkins(options={})
    sort_expr = []
    my_checkin_ids = checkins.collect(&:id)
    sort_expr.push("-10 * IN(checkin_ids, %s)" % my_checkin_ids.join(','))
    sort_expr
  end

  def my_gender_orientation
    return 1 if self.gender == 2
    return 2 if self.gender == 1
    return 0
  end

end