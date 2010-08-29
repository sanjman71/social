class Oauth < ActiveRecord::Base
  belongs_to    :user
  validates     :access_token, :presence => true, :uniqueness => {:scope => :user_id}
  validates     :name, :presence => true

  after_create  :after_create_callback
  
  protected
  
  def after_create_callback
    # import user checkins
    case name
    when 'foursquare', 'fs'
      FoursquareCheckin.send_later(:import_checkins, self.user)
    when 'facebook', 'fb'
      FacebookCheckin.send_later(:import_checkins, self.user)
    end
  end
end