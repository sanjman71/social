class LocationsController < ApplicationController
  before_filter :authenticate_user!
  
  def index
    @locations = Location.all
  end

end