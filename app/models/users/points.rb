module Users::Points
  
  # add points for linking to an account with oauth
  def add_points_for_oauth(oauth)
    case oauth.provider
    when 'facebook'
      self.points += 5
    when 'foursquare'
      self.points += 5
    when 'twitter'
      self.points += 5
    end
    self.save
  end

  # add points for a checkin
  def add_points_for_checkin(checkin)
    # number of points depends on how many checkins at this location
    count = checkins.where(:location_id => checkin.location_id).count
    add   = case count
    when 1
      5
    when 2..10
      2
    else
      1
    end
    self.points += add
    self.save
  end

  # add points for todo completed checkin
  def add_points_for_todo_completed_checkin(points)
    self.points += points
    self.save
  end

  # add points for todo expired checkin
  def add_points_for_todo_expired_checkin(points)
    self.points += points
    self.save
  end
  
  # subtract points for viewing user's profile
  def subtract_points_for_viewing_profile(user)
    self.points -= Currency.for_viewing_profile
    self.save
    Currency.for_viewing_profile
  end

end