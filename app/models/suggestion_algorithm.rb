class SuggestionAlgorithm
  
  def self.create_for(user, options={})
    @algorithm        = options[:algorithm] ? options[:algorithm] : [:checkins]
    @limit            = options[:limit] ? options[:limit].to_i : 1
    @remaining        = @limit
    @users            = []
    @users_hash       = Hash[]
    @without_user_ids = [user.id]

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
      # add to users collection
      @users            += users
      # decrement remaining users to find
      @remaining        -= @users.size
      # ensure users collection is unique
      @without_user_ids += @users.collect(&:id)
      break if @remaining <= 0
    end

    @suggestions = []
    @users.each do |u|
      @options    = Hash[:party1_attributes => {:user => user}, :party2_attributes => {:user => u},
                         :location => user.locations.first, :when => 'next week', :match => @users_hash[u.id]]
      @suggestion = Suggestion.create(@options)
      @suggestions.push(@suggestion)
    end

    @suggestions
  end

  def self.default_radius
    10
  end

end