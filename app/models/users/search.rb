module Users::Search
  
  def sightings(options={})
    options.update(:with_location_ids => [self.locations.collect(&:id)])
    options.update(:without_user_ids => [self.id])
    search(options)
  end
  
  def search(options={})
    klass       = User
    page        = options[:page] ? options[:page].to_i : 1
    per_page    = options[:per_page] ? options[:per_page] : 20
    method      = :search
    query       = options[:query] ? options[:query] : nil
    with        = Hash[]
    without     = Hash[]
    conditions  = Hash[]
    
    if options[:with_location_ids] # e.g. [1,3,5]
      with.update(:location_ids => options[:with_location_ids])
    end
    if options[:without_user_ids] # e.g. [1,2,3]
      without.update(:user_id => options[:without_user_ids])
    end

    sort_mode   = :extended
    sort_order  = "@relevance DESC"
    
    args        = Hash[:without => without, :with => with, :conditions => conditions, :sort_mode => sort_mode, :order => sort_order,
                       :match_mode => :extended, :page => page, :per_page => per_page]
    objects     = klass.send(method, query, args)
    begin
      objects.results # query sphinx and populate results
      objects
    rescue
      []
    end
  end

end