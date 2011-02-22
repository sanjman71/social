class UsersController < ApplicationController
  before_filter :authenticate_user!, :except => [:message]
  before_filter :find_user, :only => [:activate, :add_todo_request, :become, :bucks, :disable, :learn,
                                      :message, :share_drink, :show]
  before_filter :find_viewer, :only => [:show]
  respond_to    :html, :js, :json

  privilege_required 'admin', :only => [:activate, :become, :disable, :index]
  privilege_required 'manage users', :only => [:bucks], :on => :user

  # GET /users
  # GET /admin/users?limit=10&page=0&member=1
  def index
    # check general parameters
    @limit            = params[:limit] ? params[:limit].to_i : 20
    @member           = params[:member].to_i
    @pagination       = {:page => params[:page] ? params[:page].to_i : 1, :per_page => @limit}

    @search = MetaSearch::Builder.new(User, {})
    @search.build(params[:search] || {})

    if @search.search_attributes.values.any?(&:present?)
      @users = @search.all.paginate(@pagination)
    else
      @users = []
    end

    @members          = User.where(:member => 1).count
    @non_members      = User.where(:member => 0).count

    respond_to do |format|
      format.html { render(:action => 'index', :layout => 'admin') }
    end
  end

  # GET /users/geo:1.23..-23.89/radius:10?limit=5&without_user_ids=1,5,3
  # GET /users/city:chicago?limit=5&without_user_ids=1,5,3
  # GET /users/city:chicago/radius:10?limit=5&without_user_ids=1,5,3
  def search
    # check general parameters
    @without_user_ids = params[:without_user_ids] ? params[:without_user_ids].split(',').map(&:to_i).uniq.sort : nil
    @limit            = params[:limit] ? params[:limit].to_i : 5
    @member           = params[:member].to_i
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
    end

    respond_to do |format|
      format.html
      format.js
    end
  end

  # GET /users/1
  def show
    # @user, @viewer initialized in before filter

    self.class.benchmark("*** benchmark [user:#{@user.id}] #{@user.handle} profile data") do
      # find user checkins and locations, most recent checkins first
      @checkins   = @user.checkins.order("checkin_at desc").includes(:location)
      @locations  = @checkins.collect(&:location)

      # sort checkin locations by city (city.id => {name, count})
      @geo_cloud  = @locations.inject(ActiveSupport::OrderedHash.new) do |hash, location|
        hash[location.city_id] ||= {:count => 0, :name => location.city.try(:name)}
        hash[location.city_id][:count] +=1
        hash
      end.sort_by { |k, v| -1 * v[:count] }
      @city_id    = @geo_cloud.any? ? @geo_cloud.first[0] : nil
    end # benchmark

    # find user badges; add default badge if necessary
    @badges = @user.badges.order("badges.name asc")
    @badges += [Badge.default] if @badges.size < Badge.default_min

    if @viewer == @user
      # deprecated: show matching user profiles
      # @matches = @user.search_users(:limit => 20, :miles => @user.radius, :order => :sort_similar_locations)
    else
      # subtract points and add growl message
      @points = @viewer.subtract_points_for_viewing_profile(@user)
      flash.now[:growls] = [{:message => I18n.t("currency.view_profile.growl", :points => @points), :timeout => 2000}]
    end

    # track profile viewer
    flash.now[:tracker] = track_page("/users/#{@user.id}/by/#{@viewer.id}")
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

  # PUT /users/1/activate
  def activate
    # @user initialized in before filter
    @user.activate!
    flash[:notice] = "User #{@user.handle} activated"
  rescue Exception => e
    flash[:error]  = e.message
  ensure
    redirect_to(redirect_back_path(admin_users_path))
  end

  # PUT /users/1/disable
  def disable
    # @user initialized in before filter
    @user.disable!
    flash[:notice] = "User #{@user.handle} disabled"
  rescue Exception => e
    flash[:error]  = e.message
  ensure
    redirect_to(redirect_back_path(admin_users_path))
  end

  # PUT /users/1/learn
  def learn
    # @user initialized in before filter

    # add @user to current_user learn set
    # returns true if value was added to the set; false otherwise
    @added   = current_user.learns_add(@user)
    @status  = 'ok'
    @growls   = [{:message => "You're all set.  Just checkin to one of #{@user.possessive_pronoun} places.", :timeout => 2000}]
  rescue Exception => e
    @status  = 'error'
    @message = e.message
    flash[:error]  = @message
  ensure
    respond_to do |format|
      format.html { redirect_to(redirect_back_path(admin_users_path)) }
      format.json do
        render(:json => {'status' => @status, 'added' => @added, 'message' => @message, 'growls' => @growls}.to_json)
      end
    end
  end

  # GET /users/1/re/checkins/5/message/bts - 'be there soon'
  # GET /users/1/re/checkins/5/message/sad - 'share a drink?'
  def message
    # @user initialized in before filter

    # send message
    @sender   = current_user || User.find_by_oauth_token(params[:token].to_s)
    @checkin  = Checkin.find(params['checkin_id'])
    @options  = {'sender_id' => @sender.id, 'to_id' => @user.id, 'checkin_id' => @checkin.id}
    
    case params[:message]
    when 'bts'
      Resque.enqueue(UserMailerWorker, :user_be_there_soon_message, @options)
      @notice = "We'll send them a message saying you'll be there soon"
    when 'sad'
      Resque.enqueue(UserMailerWorker, :user_share_drink_message, @options)
      @notice = "We'll send them a message saying you'd like to grab a drink"
    end

    respond_to do |format|
      format.html do
        # track action
        track_page("/action/message/#{params[:message]}")
        if user_signed_in?
          flash[:tracker] = ga_tracker
          flash[:notice]  = @notice
          redirect_to(redirect_back_path(user_path(@user))) and return
        else
          flash.now[:tracker] = ga_tracker
          flash.now[:notice]  = @notice
          render and return
        end
      end
    end
  rescue Exception => e
    
  end

  # GET /users/1/share_drink
  def share_drink
    # @user initialized in before filter

    # send message
    @sender  = current_user
    @options = {'sender_id' => @sender.id, 'to_id' => @user.id}
    Resque.enqueue(UserMailerWorker, :user_share_drink_message, @options)
    @notice  = "We'll send them a note saying you'd like to grab a drink"

    # log message
    Message.log("[user:#{@sender.id}] #{@sender.handle} sent share a drink message to:#{@user.handle}")

    respond_to do |format|
      format.html do
        # track action
        track_page("/action/share/drink")
        flash[:tracker] = ga_tracker
        # set flash
        flash[:notice]  = @notice
        redirect_to(redirect_back_path(user_path(@user))) and return
      end
      format.json do
        @growls     = [{:message => @notice, :timeout => 2000}]
        @track_page = "/action/share/drink"
        render(:json => {'status' => 'ok', 'growls' => @growls, 'track_page' => @track_page}.to_json) and return
      end
    end
  end

  # PUT /users/1/add_todo_request
  def add_todo_request
    # @user initialized in before filter

    # send add_todo message
    @sender   = current_user
    @options  = {'sender_id' => @sender.id, 'to_id' => @user.id}
    Resque.enqueue(UserMailerWorker, :user_add_todo_request, @options)
    @notice   = "We'll send them a note asking them to plan a checkin"

    respond_to do |format|
      format.html do
        # track action
        track_page("/action/add_todo_request")
        flash[:tracker] = ga_tracker
        # set flash
        flash[:notice] = @notice
        redirect_to(redirect_back_path(user_path(@user))) and return
      end
      format.json do
        @growls = [{:message => @notice, :timeout => 2000}]
        render(:json => {'status' => 'ok', 'growls' => @growls}.to_json) and return
      end
    end
  end

  protected

  def find_user
    @user = params[:id] ? User.find(params[:id]) : current_user
  end

  def find_viewer
    @viewer = current_user
  end
end