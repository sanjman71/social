class UsersController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_user, :only => [:become, :bucks, :edit, :show, :update]
  before_filter :find_viewer, :only => [:show]
  respond_to    :html, :js, :json

  privilege_required 'admin', :only => [:become]
  privilege_required 'manage users', :only => [:bucks, :edit, :update], :on => :user

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
    # @user, @viewer initialized in before filter

    # find user checkins, most recent first
    @checkins   = @user.checkins.order("checkin_at desc").includes(:location)

    # find checkin locations, sort by city (city.id => {name, count})
    @locations  = @checkins.collect(&:location)
    @geo_cloud  = @locations.inject(ActiveSupport::OrderedHash.new) do |hash, location|
      hash[location.city_id] ||= {:count => 0, :name => location.city.try(:name)}
      hash[location.city_id][:count] +=1
      hash
    end.sort_by { |k, v| -1 * v[:count] }
    @city_id    = @geo_cloud.any? ? @geo_cloud.first[0] : nil

    # find user badges
    @badges     = @user.badges.order("badges.name asc")

    if @viewer == @user
      # show matching user profiles
      @matches = @user.search_users(:limit => 20, :miles => @user.radius, :order => :sort_similar_locations)
    else
      # subtract points and add growl message
      @points = @viewer.subtract_points_for_viewing_profile(@user)
      flash.now[:growls] = [{:message => I18n.t("currency.view_profile.growl", :points => @points), :timeout => 2000}]
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
      User.log("[user:#{@user.id}] #{@user.handle} updated #{params[:user].inspect}")
      flash[:notice] = "Profile updated"
    else
      flash[:error]  = "There was an error updating your profile"
    end
    redirect_back_to(edit_user_path(@user))
  end

  # GET /users/1/become
  # note: admin privileges required
  def become
    # @user initialized in before filter
    sign_in(:user, @user)
    flash[:notice] = "You are now logged in as #{@user.handle}"
    redirect_back_to(root_path)
  end

  # PUT /users/1/bucks/:points
  def bucks
    # @user initialized in before filter
    @points = params[:points].to_i
    @user.add_points(@points)
    @growls = [{:message => I18n.t("currency.add_bucks.growl", :points => @points), :timeout => 2000}]
    respond_to do |format|
      format.json do
        render :json => Hash[:points => @user.points, :growls => @growls].to_json
      end
    end
  end

  protected

  def find_user
    @user = User.find(params[:id])
  end

  def find_viewer
    @viewer = current_user
  end
end