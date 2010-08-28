module Users::Oauth
  
  def self.included(base)
    def base.find_for_github_oauth(access_token, signed_in_resource=nil)
      return unless signed_in_resource
      # parse access_token
      data  = ActiveSupport::JSON.decode(access_token.get('/api/v2/json/user/show'))["user"]
      user  = signed_in_resource
      oauth = user.oauths.find_by_name('github')
      if oauth
        # update token
        oauth.access_token = access_token.token
        oauth.save
      else
        # create oauth object with token
        oauth = user.oauths.create(:name => 'github', :access_token => access_token.token)
      end
      user
    end

    def base.find_for_facebook_oauth(access_token, signed_in_resource=nil)
      return unless signed_in_resource
      user  = signed_in_resource
      oauth = user.oauths.find_by_name('facebook')
      if oauth
        # update token
        oauth.access_token = access_token.token
        oauth.save
      else
        # create oauth object with token
        oauth = user.oauths.create(:name => 'facebook', :access_token => access_token.token)
      end
      user
    end

    def base.find_for_foursquare_oauth(access_token, signed_in_resource=nil)
      if signed_in_resource.blank?
        # create user
        begin
          data  = ActiveSupport::JSON.decode(access_token.get('http://api.foursquare.com/v1/user.json').body)["user"]
          email = data['email']
          phone = data['phone']
          fname = data['firstname']
          users = self.find_by_email_or_phone(email, phone)
          user  = case users.size
          when 1
            users.first
          when 0
            # create user
            email_hash = {"0" => {:address => email}}
            phone_hash = {"0" => {:address => phone, :name => 'Mobile'}} # assume its their mobile phone
            User.create(:handle => fname, :email_addresses_attributes => email_hash, :phone_numbers_attributes => phone_hash)
          else
            # whoops
            nil
          end
        rescue Exception => e
          user = nil
        end
        signed_in_resource = user
      end
      find_for_service_oauth('foursquare', access_token, signed_in_resource)
    end
  
    def base.find_for_service_oauth(service, access_token, signed_in_resource=nil)
      return unless signed_in_resource
      user  = signed_in_resource
      oauth = user.oauths.find_by_name(service)
      if oauth
        # update token
        oauth.access_token = access_token.token
        oauth.save
      else
        # create oauth object with token
        oauth = user.oauths.create(:name => service, :access_token => access_token.token, :access_token_secret => access_token.secret)
      end
      user
    end

    def base.foursquare_oauth_consumer
      consumer = OAuth::Consumer.new('UOPQQXD1M02JZLS1RZMCJCC23GUO0GEEOV53JANCP11ZCPFE', 'ZTYPX202I5GKITAPGTMWHE4S3ITOWYKIOBHYOPYE2VGMZ51I', 
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

  end

end