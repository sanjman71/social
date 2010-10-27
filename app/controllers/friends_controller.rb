class FriendsController < ApplicationController
  before_filter :authenticate_user!

  # privilege_required 'admin', :only => [:index]

  # GET /friends
  def index
    # initialize facebook client, find friends
    @user     = current_user
    @oauth    = Oauth.find_user_oauth(@user, 'facebook')
    @facebook = FacebookClient.new(@oauth.access_token)
    @friends  = @facebook.friends['data']
  end

end
