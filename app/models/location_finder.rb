class LocationFinder

  @@mappings = nil

  # define set of key to id mappings used to help in the matching process
  def self.mappings
    if @@mappings.blank?
      puts "*** loading mappings"
      s = YAML::load_stream(File.open("data/location_finder.yml"))
      @@mappings = s.documents
      # @@mappings = s.documents.inject(Hash[]) do |hash, document|
      #   hash.merge!(document)
      #   hash
      # end
    end
    @@mappings
  end
  
  # use sphinx to match the specified object hash to an existing location
  def self.match(object, options={})
    @name           = object['name']            # e.g. kerryman
    @address        = object['address']         # e.g. 200 w chicago, 14 Division
    @state          = object["state"].to_s      # e.g. il, illinois
    @city           = object['city'].to_s       # e.g. chicago
    @phone          = object['phone']           # e.g. 3125559999

    @log            = options[:log].to_i == 1

    puts "*** object: #{object.inspect}" if @log

    # find state by name or code
    @state          = @state.match(/^[a-zA-Z]{2,2}$/) ? State.find_by_code(@state.upcase) : State.find_by_name(@state)

    if @state.blank?
      puts "[error] missing state" if @log
      return []
    end

    # extract street name and number from address
    @address        = @address ? StreetAddress.street_name_number(@address) : @address

    # find city by name, or by resolving with 'address, city' or 'city'
    @resolvable     = @address ? "#{@address}, #{@city}" : @city
    @city           = @state.cities.find_by_name(@city) || Locality.resolve(@resolvable, :precision => :city, :create => true)

    if @city.blank?
      puts "[error] missing city" if @log
      return []
    end

    # search city
    @attributes     = Query.attributes(@city)
    @sort_order     = "@relevance desc"

    puts "*** searching using name and address" if @log

    # search query using a field search for name and address
    @query          = ["name:'#{@name}'", @address ? "address:'#{@address}'" : ''].reject(&:blank?).join(' ')
    @hash           = Query.build(@query)
    @fields         = @hash[:fields]

    @sphinx_options = Hash[:with => @attributes, :conditions => @fields, :order => @sort_order,
                           :match_mode => :extended2, :rank_mode => :bm25, :page => 1, :per_page => 5,
                           :max_matches => 100]
    @locations      = Location.search(@sphinx_options)

    if @locations.size != 1 and @phone.present?
      puts "*** searching using name and phone" if @log
      # try again with name and phone
      @query          = ["name:'#{@name}'", "phone:'#{@phone}'"].join(' ')
      @hash           = Query.build(@query)
      @fields         = @hash[:fields]

      @sphinx_options = Hash[:with => @attributes, :conditions => @fields, :order => @sort_order,
                             :match_mode => :extended2, :rank_mode => :bm25, :page => 1, :per_page => 5,
                             :max_matches => 100]
      @locations      = Location.search(@sphinx_options)
    end

    if @locations.size != 1 and @phone.present?
      puts "*** searching using phone" if @log
      # try again with just phone
      @query          = ["phone:'#{@phone}'"].join(' ')
      @hash           = Query.build(@query)
      @fields         = @hash[:fields]

      @sphinx_options = Hash[:with => @attributes, :conditions => @fields, :order => @sort_order,
                             :match_mode => :extended2, :rank_mode => :bm25, :page => 1, :per_page => 5,
                             :max_matches => 100]
      @objects        = Location.search(@sphinx_options)

      if @objects.size == 1
        # there was 1 phone match, but we require a phone and name match, so check object name with query name
        @object = @objects.first
        if (@object.name =~ /#{@name}/) || (@name =~ /#{@object.name}/)
          @locations = @objects
        end
      end
    end

    if @locations.size == 1
      puts "[test] #{@locations.inspect}"
      @location = @locations.first
      puts "[found] #{Hash["name" => @location.name, "address" => @location.street_address,
                           "city" => @location.city.try(:name)].inspect}" if @log
    end

    @locations
  end
  
  # use sphinx to match location on a phone number
  def self.match_phone(object, options={})
    @state          = object["state"].to_s     # e.g. il, illinois
    @city           = object['city'].to_s      # e.g. chicago
    @phone          = object['phone'].to_s     # e.g. 3125559999

    @log            = options[:log].to_i == 1

    puts "*** object: #{object.inspect}" if @log

    # find state, city
    @state          = @state.match(/^[a-zA-Z]{2,2}$/) ? State.find_by_code(@state.upcase) : State.find_by_name(@state)

    if @state.blank?
      puts "[error] missing state" if @log
      return []
    end

    @city           = @state.cities.find_by_name(@city) || Locality.resolve(@city, :create => true)

    if @city.blank?
      puts "[error] missing city" if @log
      return []
    end

    # search city
    @attributes     = Query.attributes(@city)
    @sort_order     = "@relevance desc"
    @query          = ["phone:'#{@phone}'"].join(' ')
    @hash           = Query.build(@query)
    @fields         = @hash[:fields]

    @sphinx_options = Hash[:with => @attributes, :conditions => @fields, :order => @sort_order,
                           :match_mode => :extended2, :rank_mode => :bm25, :page => 1, :per_page => 5,
                           :max_matches => 100]
    @objects        = Location.search(@sphinx_options)
    @objects
  end
end