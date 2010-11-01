class Photo < ActiveRecord::Base
  # validates   :user_id,   :presence => true # validation doesn't work when using nested attributes
  validates   :priority,  :presence => true
  validates   :url,       :presence => true

  belongs_to  :user

  scope :facebook,      where("source = 'facebook'")
  scope :foursquare,    where("source = 'foursquare'")
  scope :twitter,       where("source = 'twitter'")
  
  def self.default_female
    'http://foursquare.com/img/blank_girl.png'
  end
  
  def self.default_male
    'http://foursquare.com/img/blank_boy.png'
  end

  def self.default_asexual
    'images/blank-person.jpg'
  end

end