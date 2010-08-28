class SightingsController < ApplicationController
  
  def index
    @sightings = current_user.sightings
  end

end