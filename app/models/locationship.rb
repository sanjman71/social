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
  scope         :my_todo_or_checkin, where({:my_checkins.gt => 0} | {:todo_checkins.gt => 0})

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

  # find locationship and decrement the specified counter
  def self.async_decrement(user, location, counter)
    locationship = user.locationships.find_by_location_id(location.id)
    return if locationship.blank?
    locationship.decrement!(counter)
    log("[user:#{user.id}] #{user.handle} decremented locationship:#{locationship.id}:#{counter} for #{location.name}:#{location.id}")
    locationship
  end

  # after save filter
  def event_locationship_saved
    if todo_checkins == 1 and changes[:my_checkins] == [0,1]
      # checkin happened at a planned location, find the planned checkin and resolve
      user.planned_checkins.active.where(:location_id => location_id).each do |pcheckin|
        pcheckin.resolve
      end
    end
  end

  # find all user checkins at this location
  def user_checkins
    user.checkins.where(:location_id => location_id)
  end

  def self.log(s, level = :info)
    AppLogger.log(s, nil, level)
  end

end
