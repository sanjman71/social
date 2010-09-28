class UsersController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_user, :only => [:edit, :show, :update]

  privilege_required 'admin', :only => [:index]

  # GET /users
  def index
    @users = User.all
  end

  # GET /users/1
  def show
    # @user initialized in before filter

    # group checkins by source
    @checkins     = @user.checkins.group_by(&:source_type)
    @checkin_logs = @user.checkin_logs.inject(Hash[]) do |hash, log|
      mm, ss = (Time.zone.now-log.last_check_at).divmod(60)
      # track minutes ago
      hash[log.source] = mm
      hash
    end
  end

  # GET /users/1/edit
  def edit
    # @user initialized in before filter
    @show_handle_message = params[:handle].to_i == 1

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

  def find_user
    @user = User.find(params[:id])
  end

end