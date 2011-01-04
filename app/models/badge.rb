class Badge < ActiveRecord::Base
  validates   :name,  :presence => true, :uniqueness => true
  validates   :regex, :presence => true

  has_many    :badgings
  has_many    :users, :through => :badgings

  def translation
    name.to_s.downcase.gsub(' ', '_')
  end

  # reverse map a string to matching badges
  def self.reverse_map(s)
    Badge.where(:regex.matches % "%#{s}%")
  end
end