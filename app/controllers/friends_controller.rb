class FriendsController < ApplicationController
  before_filter :authenticate_user!

  # privilege_required 'admin', :only => [:index]

  # GET /friends
  def index
    # initialize facebook client, find friends
    @user     = current_user
    @friends  = @user.friends + @user.inverse_friends
  end

end
