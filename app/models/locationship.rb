class Locationship < ActiveRecord::Base
  belongs_to  :user
  belongs_to  :location
  validates   :location_id, :presence => true, :uniqueness => {:scope => :user_id}
  validates   :user_id, :presence => true
  
  scope       :my_checkins, where("locationships.my_checkins > 0")
  scope       :friend_checkins, where("locationships.friend_checkins > 0")
  scope       :planned_checkins, where("locationships.planned_checkins > 0")

  # find or create locationship and increment the specified counter
  # usually called asynchronously by delayed_job
  # counter - e.g. :checkins, :friend_checkins
  def self.async_increment(user, location, counter)
    locationship = user.locationships.find_or_create_by_location_id(location.id)
    locationship.increment!(counter)
    log(:ok, "[#{user.handle}] incremented locationship:#{locationship.id}, counter:#{counter}")
    locationship
  end

  def self.log(level, s, options={})
    CHECKINS_LOGGER.info("#{Time.now}: [#{level}] #{s}")
    if level == :error
      EXCEPTIONS_LOGGER.info("#{Time.now}: [error] #{s}")
    end
  end
end
