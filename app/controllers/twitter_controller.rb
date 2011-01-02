class TwitterController < ApplicationController
  before_filter :authenticate_user!

  # GET /twitter
  def index
    @oauth  = current_user.oauths.twitter.first
    @client = Twitter::Client.new(:oauth_token => @oauth.access_token,
                                  :oauth_token_secret => @oauth.access_token_secret)
    @followers  = @client.followers.size
    @tweets     = @client.home_timeline.size
    @friends    = (@client.friends.try(:[], 'users') || []).size
  end

end