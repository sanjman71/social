module Users::Points
  
  # add points for linking to an account with oauth
  def add_points_for_oauth(oauth)
    case oauth.name
    when 'facebook'
      self.points += 5
      self.save
    when 'foursquare'
      self.points += 5
      self.save
    when 'twitter'
      self.points += 5
      self.save
    end
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

end