class Locationship < ActiveRecord::Base
  belongs_to  :user
  belongs_to  :location
  validates   :location_id, :presence => true, :uniqueness => {:scope => :user_id}
  validates   :user_id, :presence => true
end
