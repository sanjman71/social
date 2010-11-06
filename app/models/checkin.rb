class Checkin < ActiveRecord::Base
  # ensure unique checkins, using the facebook, foursquare, whatever source_id
  validates     :user_id,       :presence => true, :uniqueness => {:scope => [:location_id, :source_id, :source_type]}
  validates     :location_id,   :presence => true
  validates     :checkin_at,    :presence => true
  validates     :source_id,     :presence => true
  validates     :source_type,   :presence => true

  belongs_to    :location, :counter_cache => :checkins_count
  belongs_to    :user, :counter_cache => :checkins_count

  after_create  :event_checkin_added

  attr_accessor :matchby, :matchvalue

  scope         :foursquare, where(:source_type => 'foursquare')
  scope         :facebook, where(:source_type => 'facebook')
  scope         :recent, :order => 'checkins.checkin_at desc'

  define_index do
    has :id, :as => :checkin_ids
    # checkin user
    has user(:id), :as => :user_ids, :facet => true
    indexes user(:handle), :as => :handle
    has user(:gender), :as => :gender
    # checkin location
    has location(:id), :as => :location_ids, :facet => true
    indexes location.tags(:name), :as => :tags
    has location.tags(:id), :as => :tag_ids, :facet => true
    # convert degrees to radians for sphinx
    has 'RADIANS(locations.lat)', :as => :lat,  :type => :float
    has 'RADIANS(locations.lng)', :as => :lng,  :type => :float
  end
  
  # user checkin was added
  def event_checkin_added
    # log data
    self.class.log(:ok, "[user:#{user.id}] #{user.handle} added checkin:#{self.id} to #{location.name}:#{location.id}")
    # update locationships
    self.delay.async_update_locationships
  end

  # user checkins were imported
  def self.event_checkins_imported(user, new_checkins, source)
    log(:ok, "[#{user.handle}] imported #{new_checkins.size} #{source} #{new_checkins.size == 1 ? 'checkin' : 'checkins'}")

    if new_checkins.any?
      # use dj to rebuild sphinx index
      Delayed::Job.enqueue(SphinxJob.new(:index => 'user'), 0)
    end

    # trigger friend checkins
    trigger_event_friend_checkins(user, source)

    if user.reload.suggestionable?
      # use dj to create suggestions
      SuggestionFactory.send_later(:create, user, Hash[:algorithm => [:checkins, :radius_tags, :tags, :gender], :limit => 1])
    else
      # send alert
      user.send_alert(:id => :need_checkins)
    end
  end

  # trigger checking friend checkins
  def self.trigger_event_friend_checkins(user, source)
    if source == 'facebook'
      # import checkins for friends without facebook oauths
      user.friends.select{ |o| o.facebook_oauth.nil? }.each do |friend|
        log(:ok, "[#{user.handle}] triggering import of facebook checkins for friend #{friend.handle}")
        FacebookCheckin.delay.async_import_checkins(friend, Hash[:since => :last, :limit => 250, :oauth_id => user.facebook_oauth.try(:id)])
      end
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
    Locationship.async_increment(user, location, :my_checkins)
    # update friend locationships
    (user.friends + user.inverse_friends).each do |friend|
      Locationship.async_increment(friend, location, :friend_checkins)
    end
  end

end