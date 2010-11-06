class UsersController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_user, :only => [:edit, :show, :update]
  respond_to    :html, :js, :json

  privilege_required 'admin', :only => [:sudo]

  # GET /users
  # GET /users/geo:1.23..-23.89/radius:10?limit=5&without_user_ids=1,5,3
  # GET /users/city:chicago?limit=5&without_user_ids=1,5,3
  # GET /users/city:chicago/radius:10?limit=5&without_user_ids=1,5,3
  def index
    # check general parameters
    @without_user_ids = params[:without_user_ids] ? params[:without_user_ids].split(',').map(&:to_i).uniq.sort : nil
    @limit            = params[:limit] ? params[:limit].to_i : 5
    @options          = Hash[:without_user_ids => @without_user_ids, :limit => @limit]

    case
    when params[:geo]
      @lat, @lng    = find_lat_lng
      @radius       = find_radius
      @options.update(:geo_origin => [@lat.radians, @lng.radians],
                      :geo_distance => 0.0..@radius.miles.meters.value)
      @users        = current_user.search_users(@options)
    when params[:city]
      @city         = find_city
      @radius       = find_radius
      @options.update(:geo_origin => [@city.lat.radians, @city.lng.radians],
                      :geo_distance => 0.0..@radius.miles.meters.value)
      @users        = current_user.search_users(@options)
    else
      @users        = User.all
    end

    respond_to do |format|
      format.html
      format.js
    end
  end

  # GET /users/1
  def show
    # @user initialized in before filter

    # find user checkins, most recent first
    @checkins = @user.checkins.order("checkin_at desc")

    # find matching user profiles
    @matches  = @user.search_users(:limit => 20, :miles => @user.radius, :order => :sort_similar_locations)

    # find user badges
    @badges   = @user.badges.order("badges.name asc")
  end

  # GET /users/1/edit
  def edit
    # @user initialized in before filter
    @show_handle_message = params[:handle].to_i == 1

  end

  # POST /users/1
  def update
    if @user.update_attributes(params[:user])
      @user.class.log(:ok, "[#{@user.handle}] updated #{params[:user].inspect}")
      flash[:notice] = "Profile updated"
    else
      flash[:error]  = "There was an error updating your profile"
    end
    redirect_back_to(user_path(@user))
  end

  # GET /users/1/sudo
  def sudo
    @user = User.find(params[:id])
    sign_in(:user, @user)
    flash[:notice] = "You are now logged in as #{@user.handle}"
    redirect_back_to(root_path)
  end

  protected

  def find_user
    @user = User.find(params[:id])
  end

end