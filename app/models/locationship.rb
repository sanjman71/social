class Locationship < ActiveRecord::Base
  belongs_to    :user
  belongs_to    :location
  validates     :location_id, :presence => true, :uniqueness => {:scope => :user_id}
  validates     :user_id, :presence => true

  after_create  :event_locationship_created
  after_save    :event_locationship_saved

  attr_reader   :planned_checkin_resolution

  scope         :my_checkins, where(:my_checkins.gt => 0)
  scope         :planned_checkins, where(:planned_checkins.gt => 0)
  scope         :friend_checkins, where(:friend_checkins.gt => 0)

  # after create filter
  def event_locationship_created
    # self.class.log(:ok, "[#{user.handle}] created locationship:#{self.id} for location #{location.name}:#{location.id}")
  end

  # find or create locationship and increment the specified counter
  # usually called asynchronously by delayed_job
  # counter - e.g. :my_checkins, :friend_checkins, :planned_checkins
  def self.async_increment(user, location, counter)
    locationship = user.locationships.find_or_create_by_location_id(location.id)
    locationship.increment!(counter)
    log(:ok, "[user:#{user.id}] #{user.handle} incremented locationship:#{locationship.id}:#{counter} for #{location.name}:#{location.id}")
    locationship
  end

  # after save filter
  def event_locationship_saved
    touch_planned_at
    resolve_planned_checkins
  end

  def user_checkins
    user.checkins.where(:location_id => location_id)
  end

  def self.log(level, s, options={})
    CHECKINS_LOGGER.info("#{Time.now}: [#{level}] #{s}")
    if level == :error
      EXCEPTIONS_LOGGER.info("#{Time.now}: [error] #{s}")
    end
  end

  protected

  # update planned_at timestamp when user plans a checkin
  def touch_planned_at
    if changes[:planned_checkins] == [0,1]
      touch(:planned_at)
    end
  end

  # resolve planned checkin when a user checks in to the location
  def resolve_planned_checkins
    if changes[:my_checkins] == [0,1] and planned_checkins == 1
      # check timestamp
      if planned_at > 7.days.ago
        @planned_checkin_resolution = :completed
      else
        @planned_checkin_resolution = :toolate
      end
      # reset planned_checkins
      decrement!(:planned_checkins)
    end
  end
end
