class LocationsController < ApplicationController
  before_filter :authenticate_user!
  respond_to    :json, :html, :js

  # GET /locations
  # GET /locations/geo:1.23..-23.89?limit=5&without_location_ids=1,5,3
  # GET /locations/geo:1.23..-23.89/radius:10?limit=5&without_location_ids=1,5,3
  # GET /locations/city:chicago?limit=5&without_location_ids=1,5,3
  # GET /locations/city:chicago/radius:10?limit=5&without_location_ids=1,5,3
  def index
    # check common parameters
    @without_location_ids = params[:without_location_ids] ? params[:without_location_ids].split(',').map(&:to_i).uniq.sort : nil
    @limit                = params[:limit] ? params[:limit].to_i : 5
    @options              = Hash[:without_location_id => @without_location_ids, :limit => @limit,
                                 :klass => Location]
    case
    when params[:geo]
      @lat, @lng    = find_lat_lng
      @radius       = find_radius
      @options.update(:geo_origin => [@lat.radians, @lng.radians],
                      :geo_distance => 0.0..@radius.miles.meters.value)
      @locations    = current_user.search_locations(@options)
    when params[:city]
      @city         = find_city
      @radius       = find_radius
      @options.update(:geo_origin => [@city.lat.radians, @city.lng.radians],
                      :geo_distance => 0.0..@radius.miles.meters.value)
      @locations    = current_user.search_locations(@options)
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

  # GET /locations/geocode/foursquare?q='chicago'
  # GET /locations/geocode/google?q='chicago'
  def geocode
    @provider = params[:provider]
    @query    = params[:q]

    begin
      case @provider
      when 'google'
        @geoloc = City.geocode(@query)
        if @geoloc.country.match(/USA|Canada/)
          @result = Hash[:status => 'ok', :street_address => @geoloc.street_address.to_s,
                         :city => @geoloc.city.to_s, :state => @geoloc.state.to_s]
        else
          @result = Hash[:status => 'ok', :city => @geoloc.city.to_s, :state => '',
                         :country => @geoloc.country.to_s]
        end
      end
    rescue Exception => e
      @result = Hash[:status => 'error', :message => e.message]
    end

    respond_to do |format|
      format.json do
        render :json => @result.to_json
      end
      format.html do
        render :text => @result.to_json
      end
    end
  end

end