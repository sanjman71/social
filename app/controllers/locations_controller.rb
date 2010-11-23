class LocationsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_location, :only => [:edit, :import_tags, :tag]
  respond_to    :json, :html, :js

  privilege_required 'admin', :only => [:edit]

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

  # GET /locations/1/edit
  def edit
    # @location initialized in before_filter
  end

  # GET /locations/1/tag
  # PUT /locations/1/tag
  def tag
    # @location initialized in before_filter
    case request.method.downcase
    when 'put'
      if (@tags = params[:tags].to_s.split(',')).any?
        @pre_tag_list  = @location.tag_list.to_a
        @location.tag_list.add(@tags)
        @location.save
        @post_tag_list = @location.tag_list.to_a
        @diff_tag_list = (@post_tag_list - @pre_tag_list).sort
        if @diff_tag_list.any?
          # add points
          current_user.add_points(Currency.for_tagging_location)
          # set growl
          flash[:growls] = [{:message => "That's #{Currency.for_tagging_location} bucks", :timeout => 2000}]
          # set flash
          flash[:notice] = "Added tags '#{@diff_tag_list.join(', ')}'"
          # log tagging event
          Location.log("[location:#{@location.id}] #{current_user.handle} added tags #{@diff_tag_list.join(',')}")
        else
          flash[:notice] = "No changes made"
        end
      end

      respond_to do |format|
        # check params[:return_to] when redirecting
        path = redirect_back_path(tag_location_path(@location))
        format.js { render(:update) { |page| page.redirect_to(path) } }
        format.html { redirect_to(path) and return }
      end
    when 'get'
      # nothing here to do
    end
  end

  # GET /locations/1/import_tags
  def import_tags
    # @location initialized in before_filter

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

  # GET /locations/geocode/foursquare?q=chicago&lat=71.23&lng=-87.55
  # GET /locations/geocode/google?q=chicago
  def geocode
    @provider = params[:provider]
    @query    = params[:q]
    @lat      = params[:lat] ? params[:lat].to_f : current_user.try(:lat).to_f
    @lng      = params[:lng] ? params[:lng].to_f : current_user.try(:lng).to_f

    begin
      case @provider
      when 'foursquare'
        @fsclient = FoursquareClient.new
        @results  = @fsclient.venue_search(:q => @query, :geolat => @lat, :geolong => @lng)
        if @results['ratelimited']
          raise Exception, @results['ratelimited']
        elsif @results['error']
          raise Exception, @results['error']
        elsif @results['groups'].present?
          @locations = @results["groups"].inject([]) do |array, group|
            # each group is a hash with possible keys: 'venues', 'type'
            # 'type' values: 'Matching Places', 'Matching Tags', not sure what else
            array += group['venues']
            array
          end
          @hash = Hash[:status => 'ok', :count => @locations.size, :locations => @locations]
        else
          @hash = Hash[:status => 'ok', :count => 0, :locations => []]
        end
      when 'google'
        @geoloc = City.geocode(@query)
        if @geoloc.country.match(/USA|Canada/)
          @loc  = Hash[:street_address => @geoloc.street_address.to_s, :city => @geoloc.city.to_s,
                       :state => @geoloc.state.to_s]
          @hash = Hash[:status => 'ok', :count => 1, :locations => [@loc]]
        else
          @loc  = Hash[:street_address => @geoloc.street_address.to_s, :city => @geoloc.city.to_s,
                       :state => '', :country => @geoloc.country.to_s]
          @hash = Hash[:status => 'ok', :count => 1, :locations => [@loc]]
        end
      end
    rescue Exception => e
      @hash = Hash[:status => 'error', :message => e.message]
    end

    respond_to do |format|
      format.json do
        render :json => @hash.to_json
      end
      format.html do
        render :text => @hash.to_json
      end
    end
  end

  protected

  def find_location
    @location = Location.find(params[:id])
  end

end