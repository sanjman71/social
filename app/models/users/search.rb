module Users::Search
  
  def search_checkins(options={})
    # find user location ids
    loc_ids = self.locations.collect(&:id)
    options.update(:with_location_ids => [loc_ids])
    options.update(:with_gender => default_gender) unless options[:with_gender]
    options.update(:without_user_ids => [self.id]) unless options[:without_user_ids]
    search(options)
  end

  def search_tags(options={})
    # find user location tag ids
    tag_ids = self.locations.collect(&:tag_ids).flatten
    options.update(:with_tag_ids => tag_ids) unless options[:with_tag_ids]
    if options[:meters] or options[:miles] and self.mappable?
      # restrict search to nearby tags
      meters = options[:meters] ? options[:meters].to_f : Math.miles_to_meters(options[:miles]).to_f
      origin = [Math.degrees_to_radians(self.lat), Math.degrees_to_radians(self.lng)]
      options.update(:geo_origin => origin, :geo_distance => 0.0..meters)
    end
    options.update(:with_gender => default_gender) unless options[:with_gender]
    options.update(:without_user_ids => [self.id]) unless options[:without_user_ids]
    search(options)
  end

  def search_geo(options={})
    # check that user is mappable
    return [] unless self.mappable?
    raise Exception, "missing radius meters or miles" if options[:meters].blank? and options[:miles].blank?
    meters = options[:meters] ? options[:meters].to_f : Math.miles_to_meters(options[:miles]).to_f
    origin = [Math.degrees_to_radians(self.lat), Math.degrees_to_radians(self.lng)]
    options.update(:geo_origin => origin, :geo_distance => 0.0..meters)
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
    when 'User'
      # parse user specific options
      if options[:with_gender] # e.g. 1, [1]
        with.update(:gender => Array(options[:with_gender]))
      end
      if options[:with_location_ids] # e.g. [1,3,5]
        with.update(:location_ids => options[:with_location_ids])
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
      objects
    rescue
      []
    end
  end

  # return the object's matchie type based on search expression value
  def matchie(default = :default)
    begin
      case sphinx_attributes['@expr']
      when 5.0..100.0
        :checkin
      when 3.0..5.0
        :tag
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

  def order_checkins_tags(hash={})
    loc_ids   = self.locations.collect(&:id)
    tag_ids   = self.locations.collect(&:tag_ids).flatten
    # weigth checkin matches more than tag matches
    sort_expr = ["5 * IN(location_ids, %s)" % loc_ids.join(','), "3 * IN(tag_ids, %s)" % tag_ids.join(',')].join(" + ")
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