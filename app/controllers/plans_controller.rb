class PlansController < ApplicationController
  before_filter :authenticate_user!
  respond_to :html

  # PUT /plans/create/1
  def create
    @location = Location.find(params[:location_id])
    @planned  = current_user.planned_locations.push(@location)
    
    respond_with(@planned, :location => root_path)
  end

  # PUT /plans/remove/1
  def remove
    
  end
end
