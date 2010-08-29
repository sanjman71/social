class Checkin < ActiveRecord::Base
  validates   :user_id, :presence => true
  validates   :location_id, :presence => true
  validates   :checkin_at, :presence => true
  validates   :source_id, :presence => true
  validates   :source_type, :presence => true
  # allow at most 1 checkin per location
  validates_uniqueness_of :user_id, :scope => [:location_id, :source_id, :source_type]
  belongs_to  :location
  belongs_to  :user

  def self.import_foursquare_checkins(user)
    checkins_start = user.checkins.count

    begin
      # find foursquare oauth tokens
      oauths = user.oauths.where(:name => 'foursquare')
      if oauths.empty?
        log("[notice] user #{user.id}:#{user.handle}: does not have foursquare oauth token")
        return 0
      end
      oauth = Foursquare::OAuth.new(FOURSQUARE_KEY, FOURSQUARE_SECRET)
      oauth.authorize_from_access(oauths.first.access_token, oauths.first.access_token_secret)
      foursquare = Foursquare::Base.new(oauth)
      if foursquare.test['response'] != 'ok'
        raise Exception, "foursquare ping failed"
      end
      log("[ok] user #{user.handle}: importing checkin history")
      history = foursquare.history
      history.each do |checkin_hash|
        import_foursquare_checkin(user, checkin_hash)
      end
    rescue Exception => e
      log("[error] user #{user.handle}: #{e.message}")
      return user.checkins.count - checkins_start
    end
    checkins_added = user.checkins.count - checkins_start
    log("[ok] user #{user.handle}: imported #{checkins_added} checkins")
    checkins_added
  end
  
  def self.log(s, options={})
    CHECKIN_LOGGER.debug("#{Time.now}: #{s}")
  end
end