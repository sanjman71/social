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
  scope         :friend_checkins, where(:friend_checkins.gt => 0)

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
    touch_todo_timestamp
    resolve_todos
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
    days_float = ((todo_at + self.class.todo_window_days.days).to_f - Time.zone.now.to_f) / 86400
    days_float.ceil
  end

  def self.todo_window_days
    7
  end
  
  def self.log(s, level = :info)
    AppLogger.log(s, nil, level)
  end

  protected

  # update todo_at timestamp when user plans a checkin
  def touch_todo_timestamp
    if changes[:todo_checkins] == [0,1]
      touch(:todo_at)
    end
  end

  # resolve any todos when a user checks in to a location
  def resolve_todos
    if changes[:my_checkins] == [0,1] and todo_checkins == 1
      # check timestamps
      if (user_first_checkin.try(:checkin_at) || Time.zone.now) < todo_at
        # user checked in before adding to todo list
        @todo_resolution = :invalid
      elsif Time.zone.now - todo_at < self.class.todo_window_days.days
        # todo was completed within the allowed window
        @todo_resolution = :completed
        # add points
        user.add_points_for_todo_completed_checkin(Currency.for_completed_todo)
        # send email
        CheckinMailer.delay.todo_completed(user, location, Currency.for_completed_todo)
      else
        # too late
        @todo_resolution = :expired
        # subtract points
        user.add_points_for_todo_expired_checkin(Currency.for_expired_todo)
        # send email
        CheckinMailer.delay.todo_expired(user, location, Currency.for_expired_todo)
      end
      # reset todo_checkins
      decrement!(:todo_checkins)
    end
  end
  
end
