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
        log(:error, "facebook oauth error #{e.message}")
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
        log(:error, "foursquare oauth error #{e.message}")
        return signed_in_resource
      end
      
      user = signed_in_resource || find_or_create_foursquare_user(data)
      user.update_from_foursquare(data)
      # initialize oauth object
      find_for_service_oauth('foursquare', access_token, user)
    end

    # generic method to create or update user's oauth token for the specified service
    def base.find_for_service_oauth(service, access_token, user=nil)
      return unless user
      oauth = user.oauths.find_by_name(service)
      # note: oauth1 uses an access_token_secret, but oauth2 does not
      if oauth
        # update token
        oauth.access_token        = access_token.token
        oauth.access_token_secret = (access_token.secret rescue nil)
        oauth.save
        log(:ok, "updated oauth token for user #{user.handle}:#{user.email_address}:#{user.phone_number}")
      else
        # create oauth object with token
        oauth = user.oauths.create(:name => service, :access_token => access_token.token, :access_token_secret => (access_token.secret rescue nil))
        log(:ok, "created oauth #{service} token for user #{user.handle}:#{user.email_address}:#{user.phone_number}")
      end
      user
    end

    def base.find_or_create_facebook_user(data)
      fbid    = data['id']
      user    = self.find_by_facebook_id(fbid)
      
      if user.blank?
        # create user, default handle is firstname
        fname     = data['first_name']
        username  = data['link'].try(:split, '/').try(:last)
        handle    = username || fname # try username first, default to first name
        gender    = data['gender']
        options   = Hash[:handle => handle, :gender => gender, :facebook_id => fbid]
        user      = User.create!(options)
        log(:ok, "created user #{user.handle}")
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
        log(:ok, "created user #{user.handle}")
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
        self.class.log(:ok, "added facebook id #{self.facebook_id} to #{self.handle}")
      end
      if data['location'] and !self.mappable?
        # add user location city
        begin
          city = Locality.resolve(data['location']['name'], :create => true)
          self.city = city
          self.class.log(:ok, "added city #{city.name} to #{self.handle}")
        rescue Exception => e
          
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
        self.class.log(:ok, "added foursquare id #{self.foursquare_id} to #{self.handle}")
      end
      if data['email'] and !self.email_addresses.collect(&:address).include?(data['email'])
        self.email_addresses.build(:address => data['email'])
        self.class.log(:ok, "added email #{data['email']} to #{self.handle}")
      end
      if data['phone'] and !self.phone_numbers.collect(&:address).include?(data['phone'])
        self.phone_numbers.build(:address => data['phone'], :name => 'Mobile')
        self.class.log(:ok, "added phone #{data['phone']} to #{self.handle}")
      end
      self.save
    end

    def base.foursquare_oauth_consumer
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

    def base.log(level, s, options={})
      USERS_LOGGER.debug("#{Time.now}: [#{level}] #{s}")
    end
  end

end