class Badge < ActiveRecord::Base
  validates   :regex, :presence => true
  validates   :name,  :presence => true

  has_many    :badgings
  has_many    :users, :through => :badgings

  def translation
    name.to_s.downcase.gsub(' ', '_')
  end

end