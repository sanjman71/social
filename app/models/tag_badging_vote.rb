class TagBadgingVote < ActiveRecord::Base
  validates   :user_id, :presence => true
  validates   :tag_badge_id, :presence => true
  validates   :voter_id, :presence => true, :uniqueness => {:scope => [:user_id, :tag_badge_id]}
  validates   :vote, :presence => true

  belongs_to  :user
  belongs_to  :tag_badge
  belongs_to  :voter, :class_name => 'User'
end
