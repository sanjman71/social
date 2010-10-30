class FacebookFriend

  def self.source
    'facebook'
  end

  def self.async_import_friends(user, options={})
    begin
      log(:ok, "[#{user.handle}] checking facebook friends")
      # find user oauth object
      oauth     = options[:oauth_id] ? Oauth.find_by_id(params[:oauth_id]) : Oauth.find_user_oauth(user, source)
      return nil if oauth.blank?
      # initialize facebook client
      facebook  = FacebookClient.new(oauth.access_token)
      friends   = facebook.friends['data']
      log(:ok, "[#{user.handle}] importing #{friends.try(:size).to_i} facebook friends")
      friends.each do |friend|
        begin
          friend_name   = friend['name']
          friend_fbid   = friend['id']
          # get basic user data from facebook
          friend_data   = facebook.user(friend_fbid)
          friend_gender = friend_data.try(:[], 'gender')
          user.friends.create!(:handle => friend_name, :name => friend_name, :facebook_id => friend_fbid)
          log(:ok, "[#{user.handle}] imported facebook friend #{friend_fbid}:#{friend_name}")
        rescue Exception => e
          log(:error, "[#{user.handle}] #{__method__.to_s} exception: #{e.message}")
        end
      end
    rescue Exception => e
      log(:error, "[#{user.handle}] #{__method__.to_s} exception: #{e.message}")
    end
  end

  def self.log(level, s, options={})
    USERS_LOGGER.info("#{Time.now}: [#{level}] #{s}")
    if level == :error
      EXCEPTIONS_LOGGER.info("#{Time.now}: [error] #{s}")
    end
  end

end