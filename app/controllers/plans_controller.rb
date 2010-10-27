class PlansController < ApplicationController
  before_filter :authenticate_user!
  respond_to    :html, :json

  # PUT /plans/add/1
  def add
    @location = Location.find(params[:location_id])
    begin
      current_user.planned_locations.push(@location)
      flash[:notice] = "We added #{@location.name} to your want to go list"
      @status        = 'ok'
    rescue Exception => e
      # @location already planned
      @status        = 'error'
      @message       = e.message
    end

    respond_with(@location) do |format|
      format.html { redirect_back_to(root_path) and return }
      format.js { render(:update) { |page| page.redirect_to(root_path) } }
      format.json { render :json => Hash[:status => @status, :message => @message].to_json }
    end
  end

  # PUT /plans/remove/1
  def remove
    @location = Location.find(params[:location_id])

    begin
      current_user.planned_locations.delete(@location)
    rescue Exception => e
      # @location not planned
    end
  
    respond_with(@location) do |format|
      format.html { redirect_back_to(root_path) and return }
    end
  end

end
