module Users::Search
  
  # search users with matching checkins
  def search_checkins(options={})
    # find user location ids
    loc_ids = self.locations.collect(&:id)
    options.update(:with_location_ids => [loc_ids])
    options.update(:with_gender => default_gender) unless options[:with_gender]
    options.update(:without_user_ids => [self.id]) unless options[:without_user_ids]
    search(options)
  end

  # search users with matching location tags
  def search_tags(options={})
    # find user location tag ids
    tag_ids = self.locations.collect(&:tag_ids).flatten
    options.update(:with_tag_ids => tag_ids) unless options[:with_tag_ids]
    if (options[:meters] or options[:miles]) and self.mappable?
      # restrict search to nearby tags
      meters = options[:meters] ? options[:meters].to_f : options[:miles].miles.meters.value
      options.update(:geo_origin => [lat.radians, lng.radians], :geo_distance => 0.0..meters)
    end
    options.update(:with_gender => default_gender) unless options[:with_gender]
    options.update(:without_user_ids => [self.id]) unless options[:without_user_ids]
    search(options)
  end

  # search users by proximity
  def search_geo(options={})
    # check that user is mappable
    return [] unless self.mappable?
    if (options[:meters] or options[:miles]) and options[:geo_origin].blank? and options[:geo_distance].blank?
      meters = options[:meters] ? options[:meters].to_f : options[:miles].miles.meters.value
      options.update(:geo_origin => [lat.radians, lng.radians], :geo_distance => 0.0..meters)
    end
    raise Exception, "missing geo origin and/or geo distance" if options[:geo_origin].blank? or options[:geo_origin].blank?
    options.update(:with_gender => default_gender) unless options[:with_gender]
    options.update(:without_user_ids => [self.id]) unless options[:without_user_ids]
    search(options)
  end

  def search_gender(options={})
    options.update(:with_gender => default_gender) unless options[:with_gender]
    search(options)
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

    case klass.to_s
    when 'Location'
      # parse location specific options
      if options[:with_location_id] # e.g. [1,3,5]
        with.update(:location_id => options[:with_location_id])
      end
      if options[:without_location_id] # e.g. [1,3,5]
        without.update(:location_id => options[:without_location_id])
      end
    when 'User'
      # parse user specific options
      if options[:with_gender] # e.g. 1, [1]
        with.update(:gender => Array(options[:with_gender]))
      end
      if options[:with_location_ids] # e.g. [1,3,5]
        with.update(:location_ids => options[:with_location_ids])
      end
      if options[:without_location_ids] # e.g. [1,3,5]
        without.update(:location_ids => options[:without_location_ids])
      end
      if options[:with_tag_ids] # e.g. [1,3,5]
        with.update(:tag_ids => options[:with_tag_ids])
      end
      if options[:without_user_ids] # e.g. [1,2,3]
        without.update(:user_id => options[:without_user_ids])
      end
    end

    if options[:geo_origin] and options[:geo_distance]
      geo[:geo]         = options[:geo_origin] # e.g. [lat, lng] (in radians)
      with['@geodist']  = options[:geo_distance]  # e.g. 0..5000 (in meters)
    end

    if options[:order]
      case options[:order]
      when :checkins
        sort_order = order_checkins
      when :checkins_tags
        sort_order = order_checkins_tags
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
        next unless o.respond_to?(:matchby)
        o.matchby = o.set_matchby(options[:order])
      end
      objects
    rescue
      []
    end
  end

  def matchiness
    sphinx_attributes.try(:[], '@expr') || 0.0
  end

  # return the object's matchby value based on search parameters and result values
  def set_matchby(order, default = :default)
    begin
      case sphinx_attributes['@expr']
      when 5.0..100.0
        :checkin
      when 3.0..5.0
        case order
        when :checkins
          :checkin
        when :checkins_tags
          :tag
        else
          default
        end
      else
        if sphinx_attributes['@geodist']
          :geo
        else
          default
        end
      end
    rescue Exception => e
      default
    end
  end

  def order_checkins(options={})
    sort_expr               = []
    my_checkin_loc_ids      = locationships.my_checkins.collect(&:location_id)
    planned_checkin_loc_ids = locationships.planned_checkins.collect(&:location_id)
    # weight my checkins over planned checkins, build expression iff not empty
    if my_checkin_loc_ids.any?
      sort_expr.push("5 * IN(location_ids, %s)" % my_checkin_loc_ids.join(','))
    end
    if planned_checkin_loc_ids.any?
      sort_expr.push("3 * IN(location_ids, %s)" % planned_checkin_loc_ids.join(','))
    end
    sort_expr.join(" + ")
  end

  def order_checkins_tags(options={})
    sort_expr = order_checkins
    tag_ids   = locations.collect(&:tag_ids).flatten.uniq.sort
    if tag_ids.any?
      sort_expr += " + " + "3 * IN(tag_ids, %s)" % tag_ids.join(',')
    end
    sort_expr
  end

  def default_gender
    case self.gender
    when 1 # female
      2 # male
    when 2 # male
      1 # femal
    end
  end

end