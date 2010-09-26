class UsersController < ApplicationController
  before_filter :authenticate_user!
  before_filter :init_user, :only => [:show, :update]

  privilege_required 'admin', :only => [:index]

  # GET /users
  def index
    @users = User.all
  end

  # GET /users/1
  def show
    @show_handle_message = params[:handle].to_i == 1

    @user = User.find(params[:id])
  end

  # POST /users/1
  def update
    if @user.update_attributes(params[:user])
      @user.log(:ok, "[#{@user.handle}] updated #{params[:user].inspect}")
      flash[:notice] = "Profile updated"
    else
      flash[:error]  = "There was an error updating your profile"
    end
    redirect_back_to(user_path(@user))
  end

  protected

  def init_user
    @user = User.find(params[:id])
  end

end