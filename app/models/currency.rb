class Currency
  
  def self.for_viewing_profile
    10
  end

  def self.for_completed_todo
    50
  end
  
  def self.for_expired_todo
    -10
  end

end