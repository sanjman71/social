class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :init_google_tracker

  include Growl
  include GoogleTracker

  helper_method :growls, :has_role?, :ga_tracker, :ga_commerce, :ga_events

  # default layout
  layout 'outlately'

  # called by devise after a successful user login
  def after_sign_in_path_for(resource_or_scope)
    case resource_or_scope
    when :user, User
      if resource_or_scope.created_recently?(1)
        # allow user to change handle
        settings_path(:handle => 1)
      else
        # the default post login page
        root_url
      end
    else
      super
    end
  end

  # Reset session for the default the sign_out redirect path method
  # def after_sign_out_path_for(resource_or_scope)
  #   session.try(:delete, :beta)
  #   super
  # end

  # use specified path if no params[:return_to]
  def redirect_back_path(path)
    params[:return_to] ? params[:return_to] : path
  end

  def redirect_back_to(path)
    redirect_to(params[:return_to] || path)
  end

  def auth_token?
    params[:token].to_s == AUTH_TOKEN
  end

  # check if current user has the specified role, on the optional authorizable object
  def has_role?(role_name, authorizable=nil)
    current_user.try(:has_role?, role_name, authorizable)
  end

  protected

  # find city using params[:city]
  def find_city
    match_city = params[:city].to_s.match(/city:([a-z-]+)/)
    match_city ? City.find_by_name_or_geocode(match_city[1]) : nil
  end

  # find lat, lng using params[:geo]
  def find_lat_lng
    match_geo  = params[:geo].to_s.match(/geo:(\d+\.\d+)..(-{0,1}\d+\.\d+)/)
    match_geo ? (@lat, @lng = match_geo[1].to_f, match_geo[2].to_f) : [nil, nil]
  end

  # find radius using params[:radius]
  def find_radius
    match_radius = params[:radius].to_s.match(/radius:(\d+)/)
    match_radius ? match_radius[1].to_i : default_radius
  end

  def default_radius
    50
  end

  def find_location
    if params[:location_id]
      @location = Location.find(params[:location_id])
    elsif params[:location]
      @location = Location.find_or_create_by_source(params[:location])
    else
      raise Exception, "missing location"
    end
  end

  def init_google_tracker
    if flash[:tracker]
      ga_tracker.concat(flash[:tracker])
      flash.delete(:tracker)
    end
    if flash[:commerce]
      ga_commerce.concat(flash[:commerce])
      flash.delete(:commerce)
    end
    if flash[:events]
      ga_events.concat(flash[:events])
      flash.delete(:events)
    end
  end

end
