class Checkin < ActiveRecord::Base
  # ensure unique checkins, using the facebook, foursquare, whatever source_id
  validates     :user_id,       :presence => true, :uniqueness => {:scope => [:location_id, :source_id, :source_type]}
  validates     :location_id,   :presence => true
  validates     :checkin_at,    :presence => true
  validates     :source_id,     :presence => true
  validates     :source_type,   :presence => true

  belongs_to    :location, :counter_cache => :checkins_count
  belongs_to    :user, :counter_cache => :checkins_count

  after_create  lambda { self.delay.async_update_locationships }

  scope         :foursquare, where(:source_type => 'foursquare')
  scope         :facebook, where(:source_type => 'facebook')
  scope         :recent, :order => 'checkins.checkin_at desc'

  def self.after_import_checkins(user, new_checkins)
    if new_checkins.any?
      # use dj to rebuild sphinx index
      Delayed::Job.enqueue(SphinxJob.new(:index => 'user'), 0)
    end

    if user.reload.suggestionable?
      # use dj to create suggestions
      SuggestionFactory.send_later(:create, user, Hash[:algorithm => [:checkins, :radius_tags, :tags, :gender], :limit => 1])
    else
      # send alert
      user.send_alert(:id => :need_checkins)
    end
  end

  def self.poll_interval
    60.minutes
  end

  def self.min_checkins_for_suggestion
    5
  end

  def self.log(level, s, options={})
    CHECKINS_LOGGER.info("#{Time.now}: [#{level}] #{s}")
    if level == :error
      EXCEPTIONS_LOGGER.info("#{Time.now}: [error] #{s}")
    end
  end
  
  protected
  
  # find or create locationships and update counters
  def async_update_locationships
    # update user locationships
    Locationship.async_increment(user, location, :checkins)
    # update friend locationships
    friends = user.friends + user.inverse_friendships
    friends.each do |friend|
      Locationship.async_increment(friend, location, :friend_checkins)
    end
  end

end