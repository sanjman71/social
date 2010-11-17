class GeocodeController < ApplicationController
  respond_to :json, :html

  # GET /geocode/foursquare?q='chicago'
  # GET /geocode/google?q='chicago'
  def search
    @provider = params[:provider]
    @query    = params[:q]

    begin
      case @provider
      when 'google'
        @geoloc = City.geocode(@query)
        if @geoloc.country.match(/USA|Canada/)
          @result = Hash[:status => 'ok', :city => @geoloc.city, :state => @geoloc.state]
        else
          @result = Hash[:status => 'ok', :city => @geoloc.city, :state => '', :country => @geoloc.country]
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