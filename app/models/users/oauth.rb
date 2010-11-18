module Users::Oauth
  
  def self.included(base)
    def base.find_for_github_oauth(access_token, signed_in_resource=nil)
      # parse access_token as an example of getting user data
      data = ActiveSupport::JSON.decode(access_token.get('/api/v2/json/user/show'))["user"]
      find_for_service_oauth('github', access_token, signed_in_resource)
    end

    # devise oauth callback to map access token to a resource/user
    def base.find_for_facebook_oauth(access_token, signed_in_resource=nil)
      begin
        data = ActiveSupport::JSON.decode(access_token.get('https://graph.facebook.com/me'))
      rescue Exception => e
        # whoops
        data = nil
        self.class.log("facebook oauth error #{e.message}", :error) rescue nil
        return signed_in_resource
      end

      user = signed_in_resource || find_or_create_facebook_user(data)
      user.update_from_facebook(data)
      # initialize oauth object
      find_for_service_oauth('facebook', access_token, user)
    end

    # devise oauth callback to map access token to a resource/user
    def base.find_for_foursquare_oauth(access_token, signed_in_resource=nil)
      begin
        data = ActiveSupport::JSON.decode(access_token.get('http://api.foursquare.com/v1/user.json').body)["user"]
      rescue Exception => e
        # whoops
        data = nil
        self.class.log("foursquare oauth error #{e.message}", :error) rescue nil
        return signed_in_resource
      end

      user = signed_in_resource || find_or_create_foursquare_user(data)
      user.update_from_foursquare(data)
      # initialize oauth object
      find_for_service_oauth('foursquare', access_token, user)
    end

    # devise oauth callback to map access token to a resource/user
    def base.find_for_twitter_oauth(access_token, signed_in_resource=nil)
      begin
        # get account info
        data = ActiveSupport::JSON.decode(access_token.get('http://api.twitter.com/1/account/verify_credentials.json').body)
      rescue Exception => e
        # whoops
        data = nil
        self.class.log("twitter oauth error #{e.message}", :error) rescue nil
        return signed_in_resource
      end

      user = signed_in_resource || find_or_create_twitter_user(data)
      user.update_from_twitter(data)
      # initialize oauth object
      find_for_service_oauth('twitter', access_token, user)
    end

    # generic method to create or update user's oauth token for the specified service
    def base.find_for_service_oauth(service, access_token, user=nil)
      return unless user
      oauth = user.oauths.find_by_provider(service)
      # note: oauth1 uses an access_token_secret, but oauth2 does not
      if oauth
        # update token
        oauth.access_token        = access_token.token
        oauth.access_token_secret = (access_token.secret rescue nil)
        oauth.save
        user.class.log("[user:#{user.id}] #{user.handle} updated oauth token")
      else
        # create oauth object with token
        oauth = user.oauths.create(:provider => service, :access_token => access_token.token,
                                   :access_token_secret => (access_token.secret rescue nil))
        user.class.log("[user:#{user.id}] #{user.handle} created oauth #{service} token")
      end
      user
    end

    def base.find_or_create_facebook_user(data)
      fbid    = data['id']
      user    = self.find_by_facebook_id(fbid)
  
      if user.blank?
        # create user
        fname     = data['first_name']
        username  = data['link'].try(:split, '/').try(:last)
        # try setting handle to facebook username, default to first name
        handle    = User.valid_facebook_handle?(username) ? username : fname
        gender    = data['gender']
        options   = Hash[:handle => handle, :gender => gender, :facebook_id => fbid]
        user      = User.create!(options)
        user.class.log("[user:#{user.id}] #{user.handle} created")
      end
      user
    end
    
    def base.find_or_create_foursquare_user(data)
      fsid  = data['id']
      user  = self.find_by_foursquare_id(fsid)
      
      if user.blank?
        # create user, default handle is firstname
        fname   = data['firstname']
        gender  = data['gender']
        options = Hash[:handle => fname, :gender => gender, :foursquare_id => fsid]
        user    = User.create!(options)
        user.class.log("[user:#{user.id}] #{user.handle} created")
      end
      user
    end

    # e.g. {"id"=>"633015812", "name"=>"Sanjay Kapoor", "first_name"=>"Sanjay", "last_name"=>"Kapoor",
    #       "link"=>"http://www.facebook.com/sanjman71", "birthday"=>"02/16",
    #       "location"=>{"id"=>108659242498155, "name"=>"Chicago, Illinois"}, "gender"=>"male", "email"=>"sanjay@jarna.com",
    #        "timezone"=>-5, "locale"=>"en_US", "verified"=>true, "updated_time"=>"2009-07-16T03:50:41+0000"}
    # e.g. {"id": "633015812", "name": "Sanjay Kapoor", "first_name": "Sanjay", "last_name": "Kapoor",
    #       "link": "http://www.facebook.com/sanjman71", "birthday": "02/16",
    #       "hometown": {"id": 108482895842493, "name": "Saratoga, California"},
    #       "location": {"id": 108659242498155, "name": "Chicago, Illinois"},
    #       "education": [{"school": {"id": 10111634660, "name": "University of California, Berkeley"},
    #                                 "year": {"id": 110605848960677, "name": "1993"}},
    #                     {school": {"id": 114526828564190, "name": "Stanford"},
    #                                "year": { "id": 110649312296565, "name": "1997"}}],
    #       "gender": "male", "interested_in": ["female"],
    #       "political": "Moderate", "website": "www.walnutplaces.com", "timezone": -5, "locale": "en_US", "verified": true,
    #       "updated_time": "2009-07-16T03:50:41+0000"}
    def update_from_facebook(data)
      return if data.blank?
      if data['id'] and self.facebook_id.blank?
        # add user facebook id
        self.facebook_id = data['id']
        self.class.log("[user:#{self.id}] #{self.handle} added facebook id #{self.facebook_id}")
      end
      if data['id'] and self.photos.facebook.count == 0
        # add user facebook photo
        self.photos.create(:source => 'facebook', :priority => 1,
                           :url => "https://graph.facebook.com/#{self.facebook_id}/picture?type=square")
        self.class.log("[user:#{self.id}] #{self.handle} added facebook photo")
      end
      if data['location'] and !self.mappable?
        begin
          # add user location city, if it exists
          city_name = data['location']['name']
          city      = Locality.resolve(city_name, :precision => :city, :create => true)
          raise Exception, "could not resolve #{city_name} to a city" if city.blank?
          self.city = city
          self.class.log("[user:#{self.id}] #{self.handle} added city #{city.name}")
        rescue Exception => e
          self.class.log("[user:#{self.id}] #{self.handle} #{__method__.to_s} error adding facebook location #{city_name}; #{e.message}", :error)
        end
      end
      self.save
    end

    # e.g {"id"=>2278601, "firstname"=>"Sanjay", "friendstatus"=>"self", "homecity"=>"Chicago, IL",
    #      "photo"=>"http://foursquare.com/img/blank_boy.png", "gender"=>"male", "phone"=>"6503876818", 
    #      "email"=>"sanjay@jarna.com", "settings"=>{"pings"=>"off", "sendtotwitter"=>false, "sendtofacebook"=>false}
    def update_from_foursquare(data)
      return if data.blank?
      if data['id'] and self.foursquare_id.blank?
        self.foursquare_id = data['id']
        self.class.log("[user:#{self.id}] #{self.handle} added foursquare id #{self.foursquare_id}")
      end
      if data['email'] and !self.email_addresses.collect(&:address).include?(data['email'])
        self.email_addresses.build(:address => data['email'])
        self.class.log("[user:#{self.id}] #{self.handle} added email #{data['email']}")
      end
      if data['phone'] and !self.phone_numbers.collect(&:address).include?(data['phone'])
        self.phone_numbers.build(:address => data['phone'], :name => 'Mobile')
        self.class.log("[user:#{self.id}] #{self.handle} added phone #{data['phone']}")
      end
      if data['photo']
        photo = self.foursquare_photo
        if photo.blank?
          # add user foursquare photo, set priority lower than facebook
          self.photos.create(:source => 'foursquare', :priority => 3, :url => data['photo'])
          self.class.log("[user:#{self.id}] #{self.handle} added foursquare photo")
        elsif photo.url != data['photo']
          # update user foursquare photo
          photo.url = data['photo']
          self.class.log("[user:#{self.id}] #{self.handle} updated foursquare photo")
        end
      end
      self.save
    end

    # e.g. {"profile_background_image_url"=>"http://s.twimg.com/a/1285097693/images/themes/theme1/bg.png",
    #       "followers_count"=>4, "description"=>nil, "profile_text_color"=>"333333",
    #       "status"=>{"retweet_count"=>nil, "contributors"=>nil, "geo"=>nil, "favorited"=>false, "place"=>nil,
    #       "source"=>"web", "in_reply_to_screen_name"=>nil, "retweeted"=>false, "truncated"=>false,
    #       "in_reply_to_user_id"=>nil, "id"=>3390797913, "coordinates"=>nil, "in_reply_to_status_id"=>nil,
    #       "text"=>"just signed up to check it out", "created_at"=>"Tue Aug 18 21:13:19 +0000 2009"},
    #       "show_all_inline_media"=>false, "following"=>false, "notifications"=>false,
    #       "profile_background_tile"=>false, "friends_count"=>0, "statuses_count"=>1,
    #       "profile_link_color"=>"0084B4",
    #       "profile_image_url"=>"http://s.twimg.com/a/1284949838/images/default_profile_0_normal.png",
    #       "favourites_count"=>0, "listed_count"=>0, "contributors_enabled"=>false,
    #       "profile_sidebar_fill_color"=>"DDEEF6", "screen_name"=>"sanjman71", "geo_enabled"=>true,
    #       "time_zone"=>nil, "profile_sidebar_border_color"=>"C0DEED", "protected"=>false, "verified"=>false,
    #       "url"=>nil, "name"=>"Sanjay Kapoor", "follow_request_sent"=>false, "profile_use_background_image"=>true,
    #       "id"=>66800741, "lang"=>"en", "utc_offset"=>nil, "created_at"=>"Tue Aug 18 21:03:45 +0000 2009",
    #       "profile_background_color"=>"C0DEED", "location"=>nil}
    def update_from_twitter(data)
      return if data.blank?
      if data['id'] and self.twitter_id.blank?
        self.twitter_id = data['id']
        self.class.log("[user:#{self.id}] #{self.handle} added twitter id #{self.twitter_id}")
      end
      if data['screen_name'] and self.twitter_screen_name.blank?
        self.twitter_screen_name = data['screen_name']
        self.class.log("[user:#{self.id}] #{self.handle} added twitter screen name #{self.twitter_screen_name}")
      end
      if data['profile_image_url']
        photo = self.twitter_photo
        if photo.blank?
          # add user twitter photo, set priority lower than the others
          self.photos.create(:source => 'twitter', :priority => 5, :url => data['profile_image_url'])
          self.class.log("[user:#{self.id}] #{self.handle} added twitter photo")
        elsif photo.url != data['profile_image_url']
          # update user twitter photo
          photo.url = data['profile_image_url']
          self.class.log("[user:#{self.id}] #{self.handle} updated twitter photo")
        end
      end
      self.save
    end

    def base.oauth_consumer_foursquare
      consumer = OAuth::Consumer.new(FOURSQUARE_KEY, FOURSQUARE_SECRET,
                {
                  :site               => "http://foursquare.com",
                  :scheme             => :header,
                  :http_method        => :post,
                  :request_token_path => "/oauth/request_token",
                  :access_token_path  => "/oauth/access_token",
                  :authorize_path     => "/oauth/authorize"
                })
      consumer
    end

    def base.oauth_consumer_twitter
      consumer = OAuth::Consumer.new(TWITTER_KEY, TWITTER_SECRET,
                {
                  :site               => "http://twitter.com",
                  :scheme             => :header,
                  :http_method        => :post,
                  :request_token_path => "/oauth/request_token",
                  :access_token_path  => "/oauth/access_token",
                  :authorize_path     => "/oauth/authorize"
                })
      consumer
    end
  end

end