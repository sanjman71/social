module Users::Search
  
  def search_checkins(options={})
    options.update(:with_gender => default_gender) unless options[:with_gender]
    options.update(:with_location_ids => [self.locations.collect(&:id)])
    options.update(:without_user_ids => [self.id]) unless options[:without_user_ids]
    search(options)
  end
  
  def search_radius(options={})
    # check that user is mappable
    return [] unless self.mappable?
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
      if options[:without_user_ids] # e.g. [1,2,3]
        without.update(:user_id => options[:without_user_ids])
      end
    end

    if options[:geo_origin] and options[:geo_distance]
      geo[:geo] = options[:geo_origin] # e.g. [lat, lng] (in radians)
      with['@geodist'] = options[:geo_distance]  # e.g. 0..5000 (in meters)
    end

    sort_mode   = :extended
    sort_order  = "@relevance DESC"
    
    if !geo.blank?
      sort_order = "@geodist ASC, @relevance DESC"
    end

    args        = Hash[:without => without, :with => with, :conditions => conditions, :sort_mode => sort_mode, :order => sort_order,
                       :match_mode => :extended, :page => page, :per_page => per_page].update(geo)
    objects     = klass.send(method, query, args)
    begin
      objects.results # query sphinx and populate results
      objects
    rescue
      []
    end
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