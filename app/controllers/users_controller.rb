class UsersController < ApplicationController
  before_filter :authenticate_user!

  privilege_required 'admin', :only => [:index]

  def index
    @users = User.all
  end

end