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
      user.update_facebook_id(data)
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
      user.update_foursquare_id(data)
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
      email   = data['email']
      phone   = data['phone']
      fname   = data['first_name']
      gender  = data['gender']
      fbid    = data['id']
      user    = self.find_by_facebook_id(fbid)
      
      if user.blank?
        # create user
        email_hash = email ? {"0" => {:address => email}} : Hash[]
        phone_hash = phone ? {"0" => {:address => phone, :name => 'Mobile'}} : Hash[]
        options    = Hash[:handle => fname, :email_addresses_attributes => email_hash, :phone_numbers_attributes => phone_hash,
                          :gender => gender, :facebook_id => fbid]
        user       = User.create!(options)
        log(:ok, "created user #{user.handle}:#{user.email_address}:#{user.phone_number}")
      end
      user
    end
    
    def base.find_or_create_foursquare_user(data)
      email   = data['email']
      phone   = data['phone']
      fname   = data['firstname']
      gender  = data['gender']
      fsid    = data['id']
      user    = self.find_by_foursquare_id(fsid)
      
      if user.blank?
        # create user
        email_hash = email ? {"0" => {:address => email}} : Hash[]
        phone_hash = phone ? {"0" => {:address => phone, :name => 'Mobile'}} : Hash[]
        options    = Hash[:handle => fname, :email_addresses_attributes => email_hash, :phone_numbers_attributes => phone_hash,
                          :gender => gender, :foursquare_id => fsid]
        user       = User.create!(options)
        log(:ok, "created user #{user.handle}:#{user.email_address}:#{user.phone_number}")
      end
      user
    end

    def update_facebook_id(data)
      return if self.facebook_id
      self.facebook_id = data['id']
      self.save
      self.class.log(:ok, "added facebook id #{self.facebook_id} to #{self.handle}:#{self.email_address}:#{self.phone_number}")
    end

    def update_foursquare_id(data)
      return if self.foursquare_id
      self.foursquare_id = data['id']
      self.save
      self.class.log(:ok, "added foursquare id #{self.foursquare_id} to #{self.handle}:#{self.email_address}:#{self.phone_number}")
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