class SightingsController < ApplicationController
  before_filter :authenticate_user!
  
  def index
    @sightings = current_user.sightings
  end

end