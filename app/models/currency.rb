class Currency

  def self.for_accepting_invite
    100
  end
  
  def self.for_viewing_profile
    10
  end

  def self.for_completed_todo
    50
  end
  
  def self.for_expired_todo
    -10
  end

  def self.for_tagging_location
    5
  end

  def self.points_for_checkin(user, checkin)
    # number of points depends on how many checkins at this location
    count = user.checkins.where(:location_id => checkin.location_id).count
    add   = case count
    when 1
      10
    when 2..10
      5
    else
      1
    end
  end

end