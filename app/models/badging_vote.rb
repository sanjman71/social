class BadgingVote < ActiveRecord::Base
  validates   :user_id, :presence => true
  validates   :badge_id, :presence => true
  validates   :voter_id, :presence => true, :uniqueness => {:scope => [:user_id, :badge_id]}
  validates   :vote, :presence => true

  belongs_to  :user
  belongs_to  :badge
  belongs_to  :voter, :class_name => 'User'
end
