class SuggestionFactory
  
  def self.create(options)
    @user             = User.find_by_id(options[:user_id])
    @algorithm        = options[:algorithm] ? options[:algorithm] : [:checkins]
    @limit            = options[:limit] ? options[:limit].to_i : 1
    @remaining        = @limit
    @users            = []
    @users_hash       = Hash[]
    # by default, no repeat suggestion users, exclude user and friends
    @without_user_ids = ([@user.id] + @user.friend_ids + @user.suggestions.collect(&:users).flatten.collect(&:id)).uniq.sort

    @algorithm.each do |algorithm|
      # base options
      @options = {:with_member => 1, :without_user_ids => @without_user_ids, :limit => @remaining}
      case algorithm
      when :geo_checkins
        # find matches based on common checkin locations within a specified radius from user
        @options.merge!(:miles => default_radius)
        users = @user.search_daters_by_checkins(@options)
        users.each { |u| @users_hash[u.id] = 'geo_checkin' }
      when :checkins
        # find matches based on common checkin locations
        users = @user.search_daters_by_checkins(@options)
        users.each { |u| @users_hash[u.id] = 'checkin' }
      when :geo_tags
        # find matches based on location tags within a specified radius from user
        @options.merge!(:miles => default_radius)
        users = @user.search_daters_by_tags(@options)
        users.each { |u| @users_hash[u.id] = 'geo_tag' }
      when :tags
        # find matches based on location tags
        users = @user.search_daters_by_tags(@options)
        users.each { |u| @users_hash[u.id] = 'tag' }
      when :geo
        # find matches based on radius from user
        @options.merge!(:miles => default_radius)
        users = @user.search_daters(@options)
        users.each { |u| @users_hash[u.id] = 'geo' }
      when :gender
        # find matches based on user gender preferences
        users = @user.search_gender(@options)
        users.each { |u| @users_hash[u.id] = 'gender' }
      else
        users = []
      end
      # append to users collection
      @users            += users
      # decrement remaining users to find
      @remaining        -= @users.size
      # ensure users collection is unique
      @without_user_ids += @users.collect(&:id)
      break if @remaining <= 0
    end

    @suggestions = []
    @users.each do |u|
      # pick a meeting location based on the suggestion match type
      @match = @users_hash[u.id]
      case @match
      when 'geo_checkin'
        @checkin_loc_ids = u.checkin_locations.collect(&:id)
        if @checkin_loc_ids.any?
          # pick a random common geo location
          @common_ids = @checkin_loc_ids & @user.checkin_locations.collect(&:id)
          options     = {:without_user_ids => [-1], :with_location_ids => @common_ids, :miles => default_radius,
                         :order => :sort_random, :limit => 1}
          @location   = @user.search_locations(options).first
        else
          # pick a random geo location
          options   = {:without_user_ids => [-1], :miles => default_radius, :order => :sort_random, :limit => 1}
          @location = @user.search_locations(options).first
        end
      else
        # pick a random geo location
        options   = {:without_user_ids => [-1], :miles => default_radius, :order => :sort_random, :limit => 1}
        @location = @user.search_locations(options).first
      end
      @options    = Hash[:party1_attributes => {:user => @user},
                         :party2_attributes => {:user => u},
                         :match => @match, :location => @location, :when => 'next week']
      @suggestion = Suggestion.create(@options)
      @suggestions.push(@suggestion)
    end

    @suggestions
  end

  def self.default_radius
    10
  end

end