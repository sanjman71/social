class TagBadge < ActiveRecord::Base
  validates   :regex,   :presence => true
  validates   :name,   :presence => true

  has_many    :tag_badgings
  has_many    :users, :through => :tag_badgings
end