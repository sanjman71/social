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
      log("[error] find_user_oauth invalid user #{user.inspect}", :error)
      return nil
    end
    oauth = user.oauths.where(:provider => provider).first
    if oauth.blank?
      log("[#{user.handle}] no #{provider} oauth token")
      return nil
    end
    oauth
  end

  def event_oauth_created
    # add user points
    user.add_points_for_oauth(self)
    # import user checkins, friends
    case provider
    when 'foursquare'
      # import all checkins, max of 250
      Resque.enqueue(FoursquareWorker, :import_checkins, 'user_id' => user.id, 'limit' => 250)
    when 'facebook'
      # import all checkins, max of 250
      Resque.enqueue(FacebookWorker, :import_checkins, 'user_id' => user.id, 'limit' => 250)
      if enabled(:import_friends)
        # import friends
        Resque.enqueue(FacebookWorker, :import_friends, 'user_id' => user.id)
      end
    end
  end

  def self.log(s, level = :info)
    AppLogger.log(s, nil, level)
  end

end