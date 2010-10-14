class LocationsController < ApplicationController
  before_filter :authenticate_user!

  # GET /locations
  # GET /locations/geo:1.23..-23.89/radius:10?limit=5&without_location_id=1,5,3
  def index
    # check generic parameters
    @without_location_id  = params[:without_location_id] ? params[:without_location_id].split(',').map(&:to_i).uniq.sort : nil
    @limit                = params[:limit] ? params[:limit].to_i : 5
    @options              = Hash[:without_location_id => @without_location_id, :limit => @limit,
                                 :klass => Location]
    case
    when (params[:geo] and params[:radius])
      match_geo     = params[:geo].to_s.match(/geo:(\d+\.\d+)..(-{0,1}\d+\.\d+)/)
      match_radius  = params[:radius].to_s.match(/radius:(\d+)/)
      @lat, @lng    = match_geo[1].to_f, match_geo[2].to_f
      @geo_origin   = [Math.degrees_to_radians(@lat), Math.degrees_to_radians(@lng)]
      @geo_distance = Math.miles_to_meters(0)..Math.miles_to_meters(match_radius[1].to_i)
      @radius       = match_radius[1].to_i
      @options.update(:geo_origin => @geo_origin, :geo_distance => @geo_distance)
      @locations    = current_user.search_geo(@options)
    when (params[:city] and params[:radius])
      match_city    = params[:city].to_s.match(/city:([a-z-]+)/)
      match_radius  = params[:radius].to_s.match(/radius:(\d+)/)
      @city         = match_city[1]
      @geoloc       = City.geocode(@city)
      @geo_origin   = [Math.degrees_to_radians(@lat), Math.degrees_to_radians(@lng)]
      @geo_distance = Math.miles_to_meters(0)..Math.miles_to_meters(match_radius[1].to_i)
      @radius       = match_radius[1].to_i
      @options.update(:geo_origin => @geo_origin, :geo_distance => @geo_distance)
      @locations    = current_user.search_geo(@options)
    else
      # default
      @locations    = Location.all
    end

    respond_to do |format|
      format.html
      format.js
    end
  end

  # GET /locations/1/import_tags
  def import_tags
    @location = Location.find(params[:id])

    @location.location_sources.each do |ls|
      case
      when ls.facebook?
        FacebookLocation.delay.async_import_tags(:location_sources => [ls])
      when ls.foursquare?
        FoursquareLocation.delay.async_import_tags(:location_sources => [ls])
      end
    end

    redirect_to(locations_path) and return
  end

end