class TagBadging < ActiveRecord::Base
  validates   :user_id,         :presence => true, :uniqueness => {:scope => :tag_badge_id}
  validates   :tag_badge_id,    :presence => true

  belongs_to  :tag_badge
  belongs_to  :user
end