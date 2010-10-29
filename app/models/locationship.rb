class Locationship < ActiveRecord::Base
  belongs_to  :user
  belongs_to  :location
  validates   :location_id, :presence => true, :uniqueness => {:scope => :user_id}
  validates   :user_id, :presence => true
  
  # find or create locationship and increment the specified counter
  # usually called asynchronously by delayed_job
  # counter - e.g. :checkins, :friend_checkins
  def self.async_increment(user, location, counter)
    locationship = user.locationships.find_or_create_by_location_id(location.id)
    locationship.increment!(counter)
  end
end
