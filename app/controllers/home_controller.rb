class HomeController < ApplicationController
  skip_before_filter :check_beta, :only => [:beta, :ping]

  # GET /
  def index
    if user_signed_in?
      # find matching checkins
      @checkins     = current_user.search_geo_checkins(:limit => checkins_start_count, :miles => current_user.radius,
                                                       :order => [:sort_similar_locations], :klass => Checkin)
      # mark checkins from me and friends
      
      # # find matching user profiles
      # @matches      = current_user.search_geo(:limit => 10, :miles => current_user.radius, :order => :checkins_tags,
      #                                         :klass => User)
      # # find nearby locations
      # @locations    = current_user.search_geo(:limit => 2, :miles => current_user.radius, :klass => Location)
      @max_objects  = checkins_end_count
    end

    # check for growl messages
    @growls = params[:growls].to_i
  end

  # GET /beta
  # POST /beta
  def beta
    if request.post?
      case params[:code].downcase
      when BETA_CODE
        session[:beta] = 1
        redirect_to(root_path) and return
      else
        session[:beta] = 0
        flash[:notice] = "Invalid access code"
        redirect_to(beta_path) and return
      end
    end
  end

  # GET /ping
  def ping
    # touch the database
    @user = User.first
    head(:ok)
  end

  protected
  
  def checkins_start_count
    3
  end

  def checkins_end_count
    8
  end

end