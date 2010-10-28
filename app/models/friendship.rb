class Friendship < ActiveRecord::Base
  belongs_to  :user
  belongs_to  :friend, :class_name => 'User'
  validates   :user_id, :presence => true, :unique_friend => true
  validates   :friend_id, :presence => true, :uniqueness => {:scope => :user_id}
end
