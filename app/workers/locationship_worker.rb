class LocationshipWorker
  # resque queue
  @queue = :normal

  def self.log(s, level = :info)
    AppLogger.log(s, nil, level)
  end

  def self.perform(method, *args)
    self.send(method, *args)
  end

  def self.friendship_created(options={})
    friendship  = Friendship.find(options['friendship_id'])
    user        = friendship.user
    friend      = friendship.friend

    # find user's checkins before this friendship was created - future checkins are handled by checkin event
    user.checkins.where("checkins.created_at < ?", friendship.created_at).each do |checkin|
      # update friend's friend_checkins
      Locationship.async_increment(friend, checkin.location, :friend_checkins)
    end

    # find friend's checkins before this friendship was created - future checkins are handled by checkin event
    friend.checkins.where("checkins.created_at < ?", friendship.created_at).each do |checkin|
      # update users's friend_checkins
      Locationship.async_increment(user, checkin.location, :friend_checkins)
    end
  end

  def self.checkin_added(options={})
    checkin   = Checkin.find(options['checkin_id'])
    user      = checkin.user
    location  = checkin.location

    # update user locationships
    Locationship.async_increment(user, location, :my_checkins)

    # update friend locationships
    (user.friends + user.inverse_friends).uniq.each do |friend|
      Locationship.async_increment(friend, location, :friend_checkins)
    end
  end

  def self.planned_checkin_added(options={})
    pcheckin  = PlannedCheckin.find(options['planned_checkin_id'])
    user      = pcheckin.user
    location  = pcheckin.location

    # increment user locationships counter
    Locationship.async_increment(user, location, :todo_checkins)
  end
end