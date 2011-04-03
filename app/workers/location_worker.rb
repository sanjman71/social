class LocationWorker
  # resque queue
  @queue = :normal

  def self.log(s, level = :info)
    AppLogger.log(s, nil, level)
  end

  def self.perform(method, *args)
    self.send(method, *args)
  end

  def self.location_created(options={})
    location  = Location.find(options['location_id'])

    # check if location needs reverse geocoding
    if location.geocoded? and location.city_id.blank? and location.street_address.blank?
      location.reverse_geocode
    end
  end

  def self.location_tagged(options={})
    location  = Location.find(options['location_id'])

    location.users.each do |user|
      # add badges for each associated user
      Resque.enqueue(BadgeWorker, :async_badge_discovery, 'user_id' => user.id)
      # propagate to user
      user.event_location_tagged(location)
    end
  end

end
