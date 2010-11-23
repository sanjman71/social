class HomeController < ApplicationController
  skip_before_filter  :check_beta, :only => [:beta, :ping]
  before_filter       :check_user_has_city

  # GET /
  def index
    if user_signed_in?
      # find matching checkins
      @user         = current_user
      @stream       = current_stream
      @geo          = current_geo || current_user
      @method       = "search_#{@stream}_checkins"
      @radius       = 2000
      @checkins     = @user.send(@method, :limit => checkins_start_count,
                                          :geo_origin => [@geo.lat.try(:radians), @geo.lng.try(:radians)],
                                          :geo_distance => 0.0..@radius.miles.meters.value,
                                          :order => [:sort_similar_locations, :sort_other_checkins, :sort_closer_locations],
                                          :group => :user)
      @streams      = ['My', 'Friends', stream_name_daters(current_user), 'Others', 'Outlately', 'Today']
      @cities       = ['Boston', 'Chicago', 'New York', 'San Francisco']
      # add user city to list of cities
      if current_user.city
        @cities.push(current_user.city.name).uniq!
      end

      @max_objects  = checkins_end_count

      logger.info("[user:#{@user.id}] #{@user.handle} geo:#{@geo.try(:name) || @geo.try(:handle)}:#{@geo.try(:lat)}:#{@geo.try(:lng)}, stream:#{@stream}")
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

  # PUT /stream/daters
  def stream
    # change the user's current stream
    session[:current_stream] = params[:name]
    redirect_to root_path and return
  end

  # PUT /geo/chicago
  def geo
    # change the user's current stream
    session[:current_geo] = params[:name]
    redirect_to root_path and return
  end

  # GET /unauthorized
  def unauthorized
  end

  protected
  
  def checkins_start_count
    3
  end

  def checkins_end_count
    8
  end

  def current_stream
    session[:current_stream] ||= default_stream
  end

  def default_stream
    'outlately'
  end

  def current_geo
    session[:current_geo] ||= default_geo
    current_geo_object
  end

  def default_geo
    # default to curren't user city, if there is one
    current_user.try(:city).try(:name).try(:downcase)
  end

  def current_geo_object
    # map geo string to city object
    City.find_by_name(session[:current_geo].try(:titleize))
  end

  def stream_name_daters(user)
    case user.gender
    when 1
      I18n.t("home.stream.name.guys")
    when 2
      I18n.t("home.stream.name.gals")
    else
      I18n.t("home.stream.name.daters")
    end
  end

  # redirect if user does not have a city
  def check_user_has_city
    if user_signed_in? and current_user.city.blank?
      flash[:notice] = "Please choose a location"
      redirect_to(edit_user_path(current_user)) and return
    end
  end
  
end