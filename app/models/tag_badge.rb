class TagBadge < ActiveRecord::Base
  validates   :regex, :presence => true
  validates   :name,  :presence => true

  has_many    :tag_badgings
  has_many    :users, :through => :tag_badgings
  
  def translation
    name.to_s.downcase.gsub(' ', '_')
  end

end