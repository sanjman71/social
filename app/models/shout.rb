class Shout < ActiveRecord::Base
  validates     :user_id,       :presence => true
  validates     :location_id,   :presence => true
  validates     :text,          :presence => true

  belongs_to    :location
  belongs_to    :user

  # define_index do
  #   has :id, :as => :shout_ids
  #   zero = "0"
  #   has zero, :as => :checkin_ids, :type => :integer
  #   has zero, :as => :todo_ids, :type => :integer
  #   has :created_at, :as => :timestamp_at
  #   # user
  #   has user(:id), :as => :user_ids
  #   indexes user(:handle), :as => :handle
  #   has user(:gender), :as => :gender
  #   has user(:member), :as => :member
  #   has user.availability(:now), :as => :now
  #   # location
  #   has location(:id), :as => :location_ids
  #   # location tags
  #   has location.tags(:id), :as => :tag_ids
  #   # convert degrees to radians for sphinx
  #   has 'RADIANS(locations.lat)', :as => :lat,  :type => :float
  #   has 'RADIANS(locations.lng)', :as => :lng,  :type => :float
  #   # use delayed job for delta index
  #   set_property :delta => :delayed
  # end

end