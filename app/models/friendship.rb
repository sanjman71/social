class Friendship < ActiveRecord::Base
  belongs_to    :user
  belongs_to    :friend, :class_name => 'User'
  validates     :user_id, :presence => true, :uniqueness => {:scope => :friend_id}, :unique_friend => true
  validates     :friend_id, :presence => true, :uniqueness => {:scope => :user_id}

  after_create  :event_friendship_created
  after_destroy :event_friendship_destroyed

  # limit the number of friends
  def self.limit
    100
  end

  # after create filter
  def event_friendship_created
    self.class.log("[user:#{user.id}] #{user.handle} added friend #{friend.handle}:#{friend.id}")
    self.class.log("[user:#{friend.id}] #{friend.handle} added inverse friend #{user.handle}:#{user.id}")
    # call async event handlers
    self.delay.async_update_locationships
    # update user friend set
    Resque.enqueue(FriendshipWorker, :update_friend_set, 'user_id' => user_id)
    Resque.enqueue(FriendshipWorker, :update_friend_set, 'user_id' => friend_id)
  end

  # after destroy filter
  def event_friendship_destroyed
    Resque.enqueue(FriendshipWorker, :update_friend_set, 'user_id' => user_id)
    Resque.enqueue(FriendshipWorker, :update_friend_set, 'user_id' => friend_id)
  end

  # user friends were imported
  def self.event_friends_imported(user, source)
    log("[user:#{user.id}] #{user.handle} imported #{(user.friends + user.inverse_friends).size} #{source} friends")
    # trigger friend checkins
    Checkin.trigger_event_friend_checkins(user, source)
  end

  def self.log(s, level = :info)
    AppLogger.log(s, nil, level)
  end

  protected
  
  # update locationships friend_checkins
  def async_update_locationships
    # find user's checkins before this friendship was created - future checkins are handled by checkin event
    user.checkins.where("checkins.created_at < ?", self.created_at).each do |checkin|
      # update friend's friend_checkins
      Locationship.async_increment(friend, checkin.location, :friend_checkins)
    end
    # find friend's checkins before this friendship was created - future checkins are handled by checkin event
    friend.checkins.where("checkins.created_at < ?", self.created_at).each do |checkin|
      # update users's friend_checkins
      Locationship.async_increment(user, checkin.location, :friend_checkins)
    end
  end

end
