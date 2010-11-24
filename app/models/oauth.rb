class Oauth < ActiveRecord::Base
  belongs_to    :user
  validates     :access_token, :presence => true, :uniqueness => {:scope => :user_id}
  validates     :provider, :presence => true, :uniqueness => {:scope => :user_id}

  after_create  :event_oauth_created

  def self.providers
    ['facebook', 'foursquare', 'twitter']
  end

  scope :facebook,      where(:provider => 'facebook')
  scope :foursquare,    where(:provider => 'foursquare')
  scope :twitter,       where(:provider => 'twitter')

  # find user oauth object specified by provider
  def self.find_user_oauth(user, provider)
    if user.is_a?(String)
      # map handle to user
      user = User.find_by_handle(user)
    end
    if user.blank?
      log(:notice, "invalid user #{user.inspect}")
      return nil
    end
    oauth = user.oauths.where(:provider => provider).first
    if oauth.blank?
      log(:notice, "[#{user.handle}] no #{provider} oauth token")
      return nil
    end
    oauth
  end

  def event_oauth_created
    # add user points
    self.user.add_points_for_oauth(self)
    # send user alert
    self.user.send_alert(:id => :linked_account)
    # import user checkins, friends
    case provider
    when 'foursquare'
      # import all checkins, max of 250
      FoursquareCheckin.delay.async_import_checkins(self.user, :limit => 250)
    when 'facebook'
      # import all checkins, max of 250
      FacebookCheckin.delay.async_import_checkins(self.user, :limit => 250)
      if IMPORT_FRIENDS == 1
        # import friends
        FacebookFriend.delay.async_import_friends(self.user)
      end
    end
  end

  def self.log(level, s, options={})
    USERS_LOGGER.info("#{Time.now}: [#{level}] #{s}")
  end
end