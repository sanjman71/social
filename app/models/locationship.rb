class Locationship < ActiveRecord::Base
  belongs_to    :user
  belongs_to    :location
  validates     :location_id, :presence => true, :uniqueness => {:scope => :user_id}
  validates     :user_id, :presence => true

  after_create  :event_locationship_created
  after_save    :event_locationship_saved

  attr_reader   :todo_resolution

  scope         :my_checkins, where(:my_checkins.gt => 0)
  scope         :todo_checkins, where(:todo_checkins.gt => 0)
  scope         :expired_todo_checkins, where(:todo_expired_at.gt => 0)
  scope         :friend_checkins, where(:friend_checkins.gt => 0)
  scope         :my_todo_or_checkin, where({:my_checkins.gt => 0} | {:todo_checkins.gt => 0})

  define_index do
    has :id, :as => :todo_ids
    has :todo_at, :as => :todo_at
    has :todo_at, :as => :timestamp_at
    # user
    has user(:id), :as => :user_ids
    indexes user(:handle), :as => :handle
    has user(:gender), :as => :gender
    has user(:member), :as => :member
    has user.availability(:now), :as => :now
    # location
    has location(:id), :as => :location_ids
    # location tags
    # indexes location.tags(:name), :as => :tags
    has location.tags(:id), :as => :tag_ids
    # convert degrees to radians for sphinx
    has 'RADIANS(locations.lat)', :as => :lat,  :type => :float
    has 'RADIANS(locations.lng)', :as => :lng,  :type => :float
    # use delayed job for delta index
    # set_property :delta => :delayed
    # only index todo locationships
    where "todo_checkins = '1' AND todo_expires_at > NOW()"
  end

  # after create filter
  def event_locationship_created
    # self.class.log(:ok, "[#{user.handle}] created locationship:#{self.id} for location #{location.name}:#{location.id}")
  end

  # find or create locationship and increment the specified counter
  # usually called asynchronously by delayed_job
  # counter - e.g. :my_checkins, :friend_checkins, :todo_checkins
  def self.async_increment(user, location, counter)
    locationship = user.locationships.find_or_create_by_location_id(location.id)
    locationship.increment!(counter)
    log("[user:#{user.id}] #{user.handle} incremented locationship:#{locationship.id}:#{counter} for #{location.name}:#{location.id}")
    locationship
  end

  # after save filter
  def event_locationship_saved
    if changes[:todo_checkins] == [0,1] and todo_at.blank?
      set_todo_timestamp
    end
    if todo_checkins == 1 and (changes[:my_checkins] == [0,1] or todo_expired?)
      # either there was a checkin or the todo has expired
      resolve_todo
    end
  end

  def todo_checkins=(i)
    if i.to_i > 0 and my_checkins > 0
      # invalid todo if location already on checkin list
      i = 0
    end
    write_attribute(:todo_checkins, i.to_i)
  end

  # find all user checkins at this location
  def user_checkins
    user.checkins.where(:location_id => location_id)
  end

  # find user's first checkin at this location
  def user_first_checkin
    user.checkins.where(:location_id => location_id).order("checkin_at asc").limit(1).first
  end

  # days left to complete checkin at this location, but only if its on the todo list
  def todo_days_left
    return 0 if todo_at.blank? or todo_checkins == 0
    days_float = (todo_expires_at.to_f - Time.zone.now.to_f) / 86400
    days_float.ceil
  end

  def todo_expired?
    # check if already expired
    return true if todo_expired_at?
    # check expires_at timestamp
    todo_expires_at ? todo_expires_at < Time.zone.now : false
  end

  def self.todo_days
    7
  end

  # expire todos based on their expiration date
  def self.expire_todos
    locships = Locationship.todo_checkins.where("todo_expires_at < ?", Time.zone.now)
    locships.each do |locship|
      locship.save
    end
    locships.size
  end

  def self.log(s, level = :info)
    AppLogger.log(s, nil, level)
  end

  protected

  def set_todo_timestamp
    # set the todo related timestamps
    touch(:todo_at)
    update_attribute(:todo_expires_at, todo_at + self.class.todo_days.days)
  end

  # resolve a todo
  def resolve_todo
    # get first checkin timestamp
    checkin_at = user_first_checkin.try(:checkin_at) || Time.zone.now
    if checkin_at < todo_at
      # user checked in before adding to todo list
      @todo_resolution = :invalid
      # reset all todo fields
      self.todo_at = self.todo_expires_at = self.todo_completed_at = self.todo_expired_at = nil
    elsif checkin_at <= todo_expires_at
      # todo was completed within the allowed window
      @todo_resolution = :completed
      # set todo_completed_at, reset todo_at + todo_expires_at
      self.todo_completed_at  = Time.zone.now
      self.todo_at = self.todo_expires_at = nil
      # add points
      user.add_points_for_todo_completed_checkin(Currency.for_completed_todo)
      if user.email_addresses_count?
        # send email
        CheckinMailer.delay.todo_completed({:user_id => user.id, :location_id => location.id,
                                            :points => Currency.for_completed_todo})
      end
    else
      # too late
      @todo_resolution = :expired
      # set todo_expired_at, reset todo_at + todo_expires_at
      self.todo_expired_at = todo_expires_at
      self.todo_at = self.todo_expires_at = nil
      # subtract points
      user.add_points_for_todo_expired_checkin(Currency.for_expired_todo)
      if user.email_addresses_count?
        # send email
        CheckinMailer.delay.todo_expired({:user_id => user.id, :location_id => location.id, :checkins => my_checkins,
                                          :points => Currency.for_expired_todo})
      end
    end
    # reset todo_checkins
    decrement!(:todo_checkins)
  end
  
end
