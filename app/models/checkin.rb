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
    has :checkin_at, :as => :checkin_at
    # checkin user
    has user(:id), :as => :user_ids
    indexes user(:handle), :as => :handle
    has user(:gender), :as => :gender
    has user(:member), :as => :member
    has user.availability(:now), :as => :now
    # checkin location
    has location(:id), :as => :location_ids
    # checkin location tags
    # indexes location.tags(:name), :as => :tags
    has location.tags(:id), :as => :tag_ids
    # convert degrees to radians for sphinx
    has 'RADIANS(locations.lat)', :as => :lat,  :type => :float
    has 'RADIANS(locations.lng)', :as => :lng,  :type => :float
    # use delayed job for delta index
    set_property :delta => :delayed
  end

  # returns true if this checkin is considered recent
  def recent_checkin?
    checkin_at > 12.hours.ago rescue false
  end

  # user checkin was added
  def event_checkin_added
    # log data
    self.class.log("[user:#{user.id}] #{user.handle} added checkin:#{self.id} to #{location.name}:#{location.id}")
    # update locationships
    self.delay.async_update_locationships
    if recent_checkin? && user.member?
      self.delay.async_email_checkin_imported
    end
  end

  # send email about the recent checkin
  def async_email_checkin_imported
    points = Currency.points_for_checkin(user, self)
    CheckinMailer.checkin_imported(self, points).deliver
  end

  # user checkins were imported
  def self.event_checkins_imported(user, new_checkins, source)
    log("[user:#{user.id}] #{user.handle} imported #{new_checkins.size} #{source} #{new_checkins.size == 1 ? 'checkin' : 'checkins'}")

    # trigger friend checkins
    trigger_event_friend_checkins(user, source)

    if user.reload.suggestionable?
      # cap the number of suggestions until this is fixed
      if user.suggestions.count < UserSuggestion.max_suggestions
        # create suggestions
        SuggestionFactory.delay.create(user, Hash[:algorithm => [:geo_checkins, :geo_tags, :gender], :limit => 1])
      end
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
        log("[user:#{user.id}] #{user.handle} triggering import of facebook checkins for friend #{friend.handle}")
        FacebookCheckin.delay.async_import_checkins(friend, Hash[:since => :last, :limit => 250, :oauth_id => user.facebook_oauth.try(:id)])
      end
    end
  end

  # trigger polling of user checkins
  def self.event_poll_checkins
    # find users with oauths, with checkin logs that haven't been checked in poll_interval
    @users = User.with_oauths.joins(:checkin_logs).
                  where(:"checkin_logs.last_check_at".lt => poll_interval.ago).select("users.*")
    
    @users.each do |user|
      user.checkin_logs.each do |log|
        # use delayed job to import these checkins
        case log.source
        when 'facebook'
          FacebookCheckin.delay.async_import_checkins(user, Hash[:since => :last, :limit => 250])
        when 'foursquare'
          FoursquareCheckin.delay.async_import_checkins(user, Hash[:sinceid => :last, :limit => 250])
        end
      end
    end
    
    @users
  end

  def self.poll_interval
    60.minutes
  end

  def self.min_checkins_for_suggestion
    5
  end

  def self.log(s, level = :info)
    AppLogger.log(s, nil, level)
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