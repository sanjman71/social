class Oauth < ActiveRecord::Base
  belongs_to    :user
  validates     :access_token, :presence => true, :uniqueness => {:scope => :user_id}
  validates     :name, :presence => true

  after_create  :after_create_callback

  scope :facebook,      where("name = 'facebook'")
  scope :foursquare,    where("name = 'foursquare'")
  scope :twitter,       where("name = 'twitter'")

  protected

  def after_create_callback
    # add user points
    self.user.add_points_for_oauth(self)
    # send user alert
    self.user.send_alert(:id => :linked_account)
    # import user checkins
    case name
    when 'foursquare', 'fs'
      # get all checkins - max of 250
      FoursquareCheckin.delay.async_import_checkins(self.user, :limit => 250)
    when 'facebook', 'fb'
      # get all checkins
      FacebookCheckin.delay.async_import_checkins(self.user, :limit => 250)
    end
  end
end