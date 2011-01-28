module GoogleTracker
  def self.included(base)
  end

  def ga_tracker
    @ga_tracker ||= []
  end

  def ga_commerce
    @ga_commerce ||= []
  end

  def ga_events
    @ga_events ||= []
  end

  def add_event(category, action, options={})
    ga_events.push("_gaq.push(['_trackEvent', '#{category.to_s.titleize}', '#{action}']);")
    ga_events
  end

  # track page view
  
  def track_page(url)
    ga_tracker.push("_gaq.push(['_trackPageview', '#{url}']);")
    ga_tracker
  end

  # login events

  def track_login_event(user, options={})
    add_event(:login, user.id)
  end

end