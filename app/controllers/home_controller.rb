class HomeController < ApplicationController
  before_filter       :authenticate_user!, :only => [:index]
  before_filter       :check_user_has_city, :only => [:index]

  # GET /
  def index
    self.class.benchmark("*** benchmark [user:#{current_user.id}] #{current_user.handle} home stream data") do
      # find data streams
      @user         = current_user
      @stream       = current_stream
      @city         = current_city || current_user
      @method       = "search_#{@stream}_data_streams"
      # validate method
      @method       = @user.respond_to?(@method) ? @method : "search_everyone_data_streams"
      @order        = [:sort_closer_locations, :sort_timestamp_at, :sort_females]
      @radius       = 100
      @objects      = @user.send(@method, :limit => checkins_start_count,
                                          :geo_origin => [@city.lat.try(:radians), @city.lng.try(:radians)],
                                          :geo_distance => 0.0..@radius.miles.meters.value,
                                          :order => @order,
                                          :group => :user)
      @streams      = streams
      @my_cities    = cities
      @pop_cities   = popular_cities

      # version
      @version      = params[:version].to_i

      # map depends on the version
      @map          = @version == 2 ? false : true
    end

    # add user city to my_cities list
    if current_user.city
      @my_cities.push(current_user.city.name).uniq!
    end

    @max_objects    = checkins_max_count
    @min_visible    = 3
    @max_visible    = 10

    Rails.logger.info("[user:#{@user.id}] #{@user.handle} geo:#{@city.try(:name) || @city.try(:handle)}:#{@city.try(:lat)}:#{@city.try(:lng)}, stream:#{@stream}")

    if params[:v].present?
      render(:action => 'index0', :layout => 'application')
    else
      render(:action => 'index')
    end
  end

  # GET /ping
  def ping
    # touch the database
    @user = User.first
    head(:ok)
  end

  # PUT /stream/:name
  # PUT /stream/daters
  def stream
    # change the user's current stream
    session[:current_stream] = params[:name]
    redirect_to root_path and return
  end

  # PUT /city/:name
  # PUT /city/chicago
  def city
    # change the user's current city
    session[:current_city] = params[:name]
    redirect_to root_path and return
  end

  # GET /about
  # GET /about?dialog=1
  def about
    if params[:dialog]
      render :layout => false
    else
      # normal render with layout
      render :layout => true
    end
  end

  # GET /unauthorized
  def unauthorized
  end

  protected
  
  def checkins_start_count
    20
  end

  def checkins_max_count
    50
  end

  def current_stream
    session[:current_stream] ||= default_stream
  end

  def streams
    [stream_name_daters(current_user), 'Friends', 'Everyone']
  end

  def default_stream
    'everyone'
  end

  def popular_cities(options={})
    limit = options[:limit] ? options[:limit].to_i : 10
    City.where(:locations_count.gt => 10).order("locations_count desc").limit(limit)
  end

  def cities
    ['Boston', 'Chicago', 'New York', 'San Francisco']
  end

  def current_city
    session[:current_city] ||= default_city
    current_city_object
  end

  def default_city
    # default to curren't user city, if there is one
    current_user.try(:city).try(:name).try(:downcase)
  end

  def current_city_object
    # map geo string to city object
    City.find_by_name(session[:current_city].try(:titleize))
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
      redirect_to(settings_path) and return
    end
  end
  
end