module Users::Oauth
  
  def self.included(base)
    def base.find_for_github_oauth(access_token, signed_in_resource=nil)
      # parse access_token as an example of getting user data
      data = ActiveSupport::JSON.decode(access_token.get('/api/v2/json/user/show'))["user"]
      find_for_service_oauth('github', access_token, signed_in_resource)
    end

    def base.find_for_facebook_oauth(access_token, signed_in_resource=nil)
      if signed_in_resource.blank?
        # find or create user
        begin
          data    = ActiveSupport::JSON.decode(access_token.get('https://graph.facebook.com/me'))
          email   = data['email']
          phone   = data['phone']
          fname   = data['first_name']
          gender  = data['gender']
          fbid    = data['id']
          users   = self.find_by_email_or_phone(email, phone)
          user    = case users.size
          when 1
            users.first
          when 0
            # create user
            email_hash = email ? {"0" => {:address => email}} : Hash[]
            phone_hash = phone ? {"0" => {:address => phone, :name => 'Mobile'}} : Hash[]
            options    = Hash[:handle => fname, :email_addresses_attributes => email_hash, :phone_numbers_attributes => phone_hash,
                              :gender => gender, :facebook_id => fbid]
            user       = User.create(options)
            log(:ok, "created user #{user.handle}:#{user.email_address}:#{user.phone_number}")
            user
          else
            # whoops
            nil
          end
        rescue Exception => e
          user = nil
        end
        signed_in_resource = user
      end

      # check if user's facebook id is set
      if signed_in_resource and signed_in_resource.facebook_id.blank?
        begin
          # get user's facebook id
          data = ActiveSupport::JSON.decode(access_token.get('https://graph.facebook.com/me'))
          signed_in_resource.facebook_id = data['id']
          signed_in_resource.save
          log(:ok, "added facebook id to #{user.handle}:#{user.email_address}:#{user.phone_number}")
        rescue Exception => e
          
        end
      end

      # initialize oauth object
      find_for_service_oauth('facebook', access_token, signed_in_resource)
    end

    def base.find_for_foursquare_oauth(access_token, signed_in_resource=nil)
      if signed_in_resource.blank?
        # find or create user
        begin
          data    = ActiveSupport::JSON.decode(access_token.get('http://api.foursquare.com/v1/user.json').body)["user"]
          email   = data['email']
          phone   = data['phone']
          fname   = data['firstname']
          gender  = data['gender']
          users   = self.find_by_email_or_phone(email, phone)
          user    = case users.size
          when 1
            users.first
          when 0
            # create user
            email_hash = email ? {"0" => {:address => email}} : Hash[]
            phone_hash = phone ? {"0" => {:address => phone, :name => 'Mobile'}} : Hash[]
            options    = Hash[:handle => fname, :email_addresses_attributes => email_hash, :phone_numbers_attributes => phone_hash,
                              :gender => gender]
            user       = User.create(options)
            log(:ok, "created user #{user.handle}:#{user.email_address}:#{user.phone_number}")
            user
          else
            # whoops
            nil
          end
        rescue Exception => e
          user = nil
        end
        signed_in_resource = user
      end

      # initialize oauth object
      find_for_service_oauth('foursquare', access_token, signed_in_resource)
    end
  
    # generic method to create or update user's oauth token for the specified service
    def base.find_for_service_oauth(service, access_token, signed_in_resource=nil)
      return unless signed_in_resource
      user  = signed_in_resource
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