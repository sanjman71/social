class SuggestionAlgorithm
  
  def self.create_for(user, options={})
    @algorithm        = options[:algorithm] ? options[:algorithm] : [:checkins]
    @limit            = options[:limit] ? options[:limit].to_i : 1
    @remaining        = @limit
    @users            = []
    @users_hash       = Hash[]
    # by default, no repeat suggestion users
    @without_user_ids = ([user.id] + user.suggestions.collect(&:users).flatten.collect(&:id)).uniq.sort

    # check that user has at least 1 checkin
    return [] if user.checkins.count == 0

    @algorithm.each do |algorithm|
      case algorithm
      when :checkins
        users = user.search_checkins(:limit => @remaining, :without_user_ids => @without_user_ids)
        users.each { |u| @users_hash[u.id] = 'checkin'}
      when :radius
        users = user.search_radius(:limit => @remaining, :without_user_ids => @without_user_ids, :miles => default_radius)
        users.each { |u| @users_hash[u.id] = 'radius'}
      when :gender
        users = user.search_gender(:limit => @remaining, :without_user_ids => @without_user_ids)
        users.each { |u| @users_hash[u.id] = 'gender'}
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
      # pick a location based on the suggestion match type
      @match = @users_hash[u.id]
      case @match
      when 'checkin'
        # pick a (random) common location
        @common   = u.locations.collect(&:id)
        @location = user.locations.where('locations.id IN (%s)' % @common.join(',')).limit(1).order('rand()').first
      else
        # pick a random location
        @location = user.locations.limit(1).order('rand()').first
      end
      @options    = Hash[:party1_attributes => {:user => user}, :party2_attributes => {:user => u}, :match => @match,
                         :location => @location, :when => 'next week']
      @suggestion = Suggestion.create(@options)
      @suggestions.push(@suggestion)
    end

    @suggestions
  end

  def self.default_radius
    10
  end

end