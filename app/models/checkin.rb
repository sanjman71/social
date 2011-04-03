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

  scope         :member, joins(:user).where(:users => {:member => 1})

  include Checkins::Match

  # define_index do
  #   has :id, :as => :checkin_ids
  #   zero = "0"
  #   has zero, :as => :todo_ids, :type => :integer
  #   has zero, :as => :shout_ids, :type => :integer
  #   has :checkin_at, :as => :checkin_at
  #   has :checkin_at, :as => :timestamp_at
  #   # checkin user
  #   has user(:id), :as => :user_ids
  #   indexes user(:handle), :as => :handle
  #   has user(:gender), :as => :gender
  #   has user(:member), :as => :member
  #   has user.availability(:now), :as => :now
  #   # checkin location
  #   has location(:id), :as => :location_ids
  #   # checkin location tags
  #   has location.tags(:id), :as => :tag_ids
  #   # convert degrees to radians for sphinx
  #   has 'RADIANS(locations.lat)', :as => :lat,  :type => :float
  #   has 'RADIANS(locations.lng)', :as => :lng,  :type => :float
  #   # use delayed job for delta index
  #   set_property :delta => :delayed
  #   # only index active users
  #   where "users.state = 'active'"
  # end

  # returns true if this checkin is more recent than the specified time
  def checkin_since?(time=2.hours.ago)
    checkin_at > time rescue false
  end

  # user checkin was added
  def event_checkin_added
    # log data
    self.class.log("[user:#{user.id}] #{user.handle} imported checkin:#{self.id} to #{location.name}:#{location.id}")
    # update locationships
    Resque.enqueue(LocationshipWorker, :checkin_added, 'checkin_id' => id)
    if checkin_since?(12.hours.ago) && user.member? && user.email_addresses_count?
      if user.preferences_import_checkin_emails.to_i == 1
        self.class.log("[user:#{user.id}] #{user.handle} sending checkin email to #{user.email_address}")
        # send imported checkin email
        Resque.enqueue(CheckinMailerWorker, :imported_checkin, 'checkin_id' => self.id,
                                            'points' => Currency.points_for_checkin(user, self))
      end
      # search for learn matches
      Resque.enqueue(CheckinWorker, :search_learn_matches, 'checkin_id' => self.id)
    end
    if checkin_since?(12.hours.ago)
      # send checkin to friends
      Resque.enqueue(CheckinWorker, :send_realtime_friend_checkin, 'checkin_id' => self.id)
    end
    if checkin_since?(1.hour.ago) && user.member?
      # mark member with a recent checkin as out
      Realtime.mark_user_as_out(user, self)
    end
  end

  # user checkins were imported
  def self.event_checkins_imported(user, new_checkins, source)
    log("[user:#{user.id}] #{user.handle} imported #{new_checkins.size} #{source} checkin(s)")

    # trigger friend checkins
    # trigger_event_friend_checkins(user, source)

    if enabled(:user_suggestions) and user.reload.suggestionable?
      # cap the number of suggestions until this is fixed
      if user.suggestions.count < UserSuggestion.max_suggestions
        # create suggestions
        SuggestionFactory.delay.create({:user_id => user.id, :algorithm => [:geo_checkins, :geo_tags, :gender],
                                        :limit => 1})
      end
    end
  end

  # trigger checking friend checkins
  # def self.trigger_event_friend_checkins(user, source)
  #   if source == 'facebook'
  #     # import checkins for non-member friends, not recently checked (without facebook oauths)
  #     user.friends.non_member.active.joins(:checkin_logs).
  #          where(:"checkin_logs.last_check_at".lt => poll_interval_default.ago).each do |friend|
  #       # priority 0 is highest and default; import checkins at a lower priority
  #       log("[user:#{user.id}] #{user.handle} triggering import of facebook checkins for friend #{friend.handle}")
  #       FacebookCheckin.delay(:priority => 5).async_import_checkins({:user_id => friend.id, :since => :last,
  #                                                                    :limit => 250,
  #                                                                    :oauth_id => user.facebook_oauth.try(:id)})
  #     end
  #   end
  # end

  def self.poll_interval(user=nil)
    begin
      user.member? ? poll_interval_member : poll_interval_default
    rescue
      poll_interval_default
    end
  end

  # different poll interval for members vs non-members

  def self.poll_interval_member
    10.minutes
  end

  def self.poll_interval_default
    60.minutes
  end

  def self.min_checkins_for_suggestion
    5
  end

  def self.log(s, level = :info)
    AppLogger.log(s, nil, level)
  end

end