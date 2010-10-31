class Friendship < ActiveRecord::Base
  belongs_to    :user
  belongs_to    :friend, :class_name => 'User'
  validates     :user_id, :presence => true, :unique_friend => true
  validates     :friend_id, :presence => true, :uniqueness => {:scope => :user_id}

  after_create  :event_friendship_created

  # after create filter
  def event_friendship_created
    self.class.log(:ok, "[#{user.handle}] added friend #{friend.handle}")
    self.class.log(:ok, "[#{friend.handle}] added inverse friend #{user.handle}")
    # call async event handlers
    self.delay.async_update_locationships
  end

  # user friends were imported
  def self.event_friends_imported(user, source)
    log(:ok, "[#{user.handle}] imported #{(user.friends + user.inverse_friends).size} #{source} friends")

    # trigger friend checkins
    Checkin.trigger_event_friend_checkins(user, source)
  end

  def self.log(level, s, options={})
    USERS_LOGGER.info("#{Time.now}: [#{level}] #{s}")
    if level == :error
      EXCEPTIONS_LOGGER.info("#{Time.now}: [error] #{s}")
    end
  end

  protected
  
  # update locationships friend_checkins
  def async_update_locationships
    # find user's checkins before this friendship was created - future checkins are handled by checkin event
    user.checkins.where("checkins.created_at < ?", self.created).each do |checkin|
      # update friend's friend_checkins
      Locationship.async_increment(friend, checkin.location, :friend_checkins)
    end
    # find friend's checkins before this friendship was created - future checkins are handled by checkin event
    friend.checkins.where("checkins.created_at < ?", self.created).each do |checkin|
      # update users's friend_checkins
      Locationship.async_increment(user, checkin.location, :friend_checkins)
    end
  end

end
