class SightingsController < ApplicationController
  before_filter :authenticate_user!
  
  # deprecated for now
  def index
    @sightings = current_user.search_checkins
  end

end