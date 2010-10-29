class Friendship < ActiveRecord::Base
  belongs_to    :user
  belongs_to    :friend, :class_name => 'User'
  validates     :user_id, :presence => true, :unique_friend => true
  validates     :friend_id, :presence => true, :uniqueness => {:scope => :user_id}

  after_create  lambda { self.delay.async_update_locationships }

  protected
  
  # update locationships friend_checkins
  def async_update_locationships
    # find user's checkins
    user.checkins.each do |checkin|
      # update friend's friend_checkins
      Locationship.async_increment(friend, checkin.location, :friend_checkins)
    end
    # find friend's checkins
    friend.checkins.each do |checkin|
      # update users's friend_checkins
      Locationship.async_increment(user, checkin.location, :friend_checkins)
    end
  end

end
