class Point

  # return the number of checkin points using the location and the number of times checked in
  def self.checkin_points(location, count)
    case count
    when 1
      5
    when 2..10
      2
    else
      1
    end
  end

end