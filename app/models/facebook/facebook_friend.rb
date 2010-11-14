class FacebookFriend

  def self.source
    'facebook'
  end

  def self.async_import_friends(user, options={})
    begin
      log("[user:#{user.id}] #{user.handle} checking facebook friends")
      # find user oauth object
      oauth     = options[:oauth_id] ? Oauth.find_by_id(params[:oauth_id]) : Oauth.find_user_oauth(user, source)
      return nil if oauth.blank?
      # initialize facebook client
      facebook  = FacebookClient.new(oauth.access_token)
      friends   = facebook.friends['data']
      log("[user:#{user.id}] #{user.handle} importing facebook friends with checkins")
      friends.each do |friend_hash|
        # check friend limit
        break if user.friends.count >= FRIEND_LIMIT
        begin
          friend_name     = friend_hash['name']
          friend_fbid     = friend_hash['id']
          # check if user already exists
          friend          = User.find_by_facebook_id(friend_fbid)
          if friend
            # user already exists, check friend relationship
            if !(user.friends + user.inverse_friends).include?(friend)
              # add friendship
              user.friendships.create(:friend => friend)
            end
          else
            # check user's checkin data
            friend_checkins = facebook.checkins(friend_fbid, options)['data']
            # skip if friend has no checkins
            next if friend_checkins.try(:size).to_i == 0
            # get basic user data from facebook
            friend_data     = facebook.user(friend_fbid)
            friend_gender   = friend_data.try(:[], 'gender')
            # create friend
            friend          = user.friends.create!(:handle => friend_name, :facebook_id => friend_fbid,
                                                   :gender => friend_gender)
            log("[user:#{user.id}] #{user.handle} imported facebook friend #{friend.handle}:#{friend_fbid}")
          end
        rescue Exception => e
          log("[user:#{user.id}] #{user.handle} #{__method__.to_s} exception: #{e.message}", :error)
        end
      end
      # send event
      Friendship.event_friends_imported(user, source)
    rescue Exception => e
      log("[#{user.handle}] #{__method__.to_s} exception: #{e.message}", :error)
    end
  end

  def self.log(s, level = :info)
    Checkin.log(s, level)
  end
end