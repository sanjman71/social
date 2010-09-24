class LocationsController < ApplicationController
  before_filter :authenticate_user!

  # GET /locations
  def index
    @locations = Location.all
  end

  # GET /locations/1/import_tags
  def import_tags
    @location = Location.find(params[:id])

    @location.location_sources.each do |ls|
      case
      when ls.facebook?
        FacebackLocation.import_tags(:location_sources => [ls])
      when ls.foursquare?
        FoursquareLocation.import_tags(:location_sources => [ls])
      end
    end

    redirect_to(locations_path) and return
  end

end