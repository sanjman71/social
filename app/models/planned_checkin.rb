class PlannedCheckin < ActiveRecord::Base
  validates     :user_id,       :presence => true
  validates     :location_id,   :presence => true
  validates     :planned_at,    :presence => true

  belongs_to    :location
  belongs_to    :user

  before_validation(:on => :create) do
    self.active = 1
    # set default planned_at
    self.planned_at = Time.zone.now if self.planned_at.blank?
    # set expires_at based on going_at if present; otherwise use default value
    self.expires_at = self.going_at if self.going_at.present?
    self.expires_at ||= self.planned_at + self.class.todo_days.days unless self.expires_at
    # check for active objects
    actives = self.class.where(:user_id => user_id, :location_id => location_id, :active => 1)
    errors.add(:base, "multiple active planned checkins are not allowed") if actives.any?
  end

  after_create  :event_planned_checkin_added
  after_save    :event_planned_checkin_saved

  scope         :active, where(:active => 1)
  scope         :inactive, where(:active => 0)
  scope         :not_expired, lambda { where(:expires_at.gt => Time.zone.now) }
  scope         :expired, lambda { where(:expires_at.lt => Time.zone.now) }

  define_index do
    has :id, :as => :todo_ids
    zero = "0"
    has zero, :as => :checkin_ids, :type => :integer
    has zero, :as => :shout_ids, :type => :integer
    has :planned_at, :as => :timestamp_at
    # user
    has user(:id), :as => :user_ids
    indexes user(:handle), :as => :handle
    has user(:gender), :as => :gender
    has user(:member), :as => :member
    has user.availability(:now), :as => :now
    # location
    has location(:id), :as => :location_ids
    # location tags
    has location.tags(:id), :as => :tag_ids
    # convert degrees to radians for sphinx
    has 'RADIANS(locations.lat)', :as => :lat,  :type => :float
    has 'RADIANS(locations.lng)', :as => :lng,  :type => :float
    # use delayed job for delta index
    set_property :delta => :delayed
    # only index non-expired objects
    where "expires_at > NOW()"
  end

  # days left to complete checkin at this location
  def expires_days_left
    return 0 if !active
    days_float = (expires_at.to_f - Time.zone.now.to_f) / 86400
    days_float.ceil
  end

  def going
    if going_at.present?
      days = (going_at.to_f - Time.zone.now.to_f) / 86400
      I18n.t("plans.going", :count => days.round)
    else
      I18n.t("plans.going_soon")
    end
  end

  # days left before planned visit
  def going_days_left
    return nil if going_at.blank?
    days = (going_at.to_f - Time.zone.now.to_f) / 86400
    days.round
  end

  def expired?
    (expires_at < Time.zone.now)
  end

  # planned checkin was added
  def event_planned_checkin_added
    # log data
    self.class.log("[user:#{user.id}] #{user.handle} added planned_checkin:#{self.id} to #{location.name}:#{location.id}")
    # update locationships
    self.delay.async_update_locationships
    # send email
    Resque.enqueue(CheckinMailerWorker, :todo_added, 'planned_checkin_id' => self.id, 'points' => Currency.for_completed_todo)
  end

  # find or create locationship, and update counters
  def async_update_locationships
    # increment user locationships counter
    Locationship.async_increment(user, location, :todo_checkins)
  end

  # planned checkin was saved
  def event_planned_checkin_saved
    if changes[:active] == [1,0]
      # decrement user locationships counter
      Locationship.async_decrement(user, location, :todo_checkins)
    end
  end

  def resolve
    return :inactive if !active?

    # find all user checkins to this location in the interval [planned_at, expires_at]
    user_checkins = user.checkins.where(:location_id => location_id, :checkin_at.gte => planned_at, :checkin_at.lte => expires_at)

    if user_checkins.any?
      # mark as completed, inactive
      update_attribute(:completed_at, user_checkins.first.checkin_at)
      update_attribute(:active, 0)
      # add points
      user.add_points_for_completed_planned_checkin(Currency.for_completed_todo)
      if user.email_addresses_count?
        # send email
        CheckinMailer.delay.todo_completed({:user_id => user.id, :location_id => location.id,
                                            :points => Currency.for_completed_todo})
      end
      return :completed
    end

    # check expired state
    if expired?
      # mark as inactive
      update_attribute(:active, 0)
      # subtract points
      user.add_points_for_expired_planned_checkin(Currency.for_expired_todo)
      if user.email_addresses_count?
        # send email
        CheckinMailer.delay.todo_expired({:user_id => user.id, :location_id => location.id,
                                          :points => Currency.for_expired_todo})
      end
      return :expired
    end
  end

  def self.todo_days
    7
  end

  # expire planned checkins based on expires_at date
  def self.expire_all
    pcheckins = self.where(:expires_at.lt => Time.zone.now, :active => 1)
    pcheckins.each do |pcheckin|
      pcheckin.resolve
    end
    pcheckins.size
  end

  def self.log(s, level = :info)
    AppLogger.log(s, nil, level)
  end

end