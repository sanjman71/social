class Badging < ActiveRecord::Base
  validates   :user_id,     :presence => true, :uniqueness => {:scope => :badge_id}
  validates   :badge_id,    :presence => true

  belongs_to  :badge
  belongs_to  :user
end