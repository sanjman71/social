module CheckinsHelper

  def checkin_time_ago(timestamp)
    hash = distance_of_time_in_words_hash(Time.zone.now, timestamp)
    if hash['months'] and hash['months'] != 0
      "#{pluralize(hash['months'], 'month')} ago"
    elsif hash['days'] and hash['days'] != 0
      "#{pluralize(hash['days'], 'day')} ago"
    elsif hash['hours'] and hash['hours'] != 0
      "#{pluralize(hash['hours'], 'hours')} ago"
    else
      # default
      distance_of_time_in_words(Time.zone.now, timestamp) + " ago"
    end
  end

end