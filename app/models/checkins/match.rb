module Checkins::Match

  def match_strategies(strategies, options={})
    limit   = options[:limit].to_i
    matches = strategies.inject([]) do |array, strategy|
      case limit
      when 1..2**30
        # no repeate checkins or users, group each set of results to 1 per user
        checkin_ids = array.collect(&:id)
        user_ids    = array.collect(&:user_id)
        hash        = {:limit => limit, :without_checkin_ids => checkin_ids, :without_user_ids => user_ids, :group => :user}
        results     = send("match_#{strategy}", hash)
      else
        results     = []
      end
      # adjust limit based on current result set
      limit -= results.size
      array + results
    end

    matches
  end

  # find dater checkins with matching locations
  def match_exact(options={})
    location_ids = [location.id]
    options.merge!(:with_location_ids => location_ids, :order => :sort_timestamp_at)
    user.search_daters_checkins(options)
  end

  # find dater checkins with similar locations
  def match_similar(options={})
    # set geo center based on location coordinates
    tag_ids = location.tag_ids
    # no matches if there are no tags
    return [] if tag_ids.blank?
    options.merge!(:with_tag_ids => tag_ids, :order => :sort_similar_locations, :miles => 50,
                   :geo_origin => [location.lat.radians, location.lng.radians],
                   :order => :sort_timestamp_at)
    user.search_daters_checkins(options)
  end

  def match_nearby(options={})
    []
  end
end