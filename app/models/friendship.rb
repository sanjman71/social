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
    # update locationships
    Resque.enqueue(LocationshipWorker, :friendship_created, 'friendship_id' => id)
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
    # deprecated
    # trigger friend checkins
    # Checkin.trigger_event_friend_checkins(user, source)
  end

  def self.log(s, level = :info)
    AppLogger.log(s, nil, level)
  end

end
