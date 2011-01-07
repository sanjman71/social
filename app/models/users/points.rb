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

  # add points
  def add_points(points)
    self.points += points
    self.save
  end

  # add points for completed planned checkin
  def add_points_for_completed_planned_checkin(points)
    self.points += points
    self.save
  end

  # add points for expired planned checkin
  def add_points_for_expired_planned_checkin(points)
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