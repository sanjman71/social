class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :check_beta

  include Growl

  helper_method :growls

  # default application layout
  layout 'application'

  # called by devise after a successful user login
  def after_sign_in_path_for(resource_or_scope)
    case resource_or_scope
    when :user, User
      if resource_or_scope.created_recently?(1)
        # allow user to change handle
        edit_user_path(resource_or_scope, :handle => 1)
      else
        # the default post login page
        root_url
      end
    else
      super
    end
  end

  def redirect_back_to(path)
    redirect_to(params[:return_to] || path)
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

  # def build_geo_origin(lat_degrees, lng_degrees)
  #   [lat_degrees.radians, lng_degrees.radians]
  # end

  # def geo_distance(radius)
  #   0.0..radius.miles.meters.value
  # end

  def default_radius
    50
  end

  # check that user has signed up for the beta
  def check_beta
    if session[:beta].to_i != 1
      redirect_to(beta_path) and return
    end
  end

end
