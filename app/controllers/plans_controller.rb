class PlansController < ApplicationController
  before_filter :authenticate_user!
  respond_to    :html, :json

  # PUT /plans/add/1
  def add
    @location = Location.find(params[:location_id])
    @user     = current_user

    begin
      # update locationship
      @locationship = @user.locationships.find_or_create_by_location_id(@location.id)
      if @locationship.planned_checkins == 0
        @locationship.increment!(:planned_checkins)
      end
      flash[:notice]  = "We added #{@location.name} to your want to go list"
      @status         = 'ok'
    rescue Exception => e
      # @location already planned
      @status         = 'error'
      @message        = e.message
    end

    # test growl messages
    @growls = [{:message => '-3 points', :timeout => 2000}]

    respond_with(@location) do |format|
      format.html { redirect_back_to(root_path) and return }
      format.js { render(:update) { |page| page.redirect_to(root_path) } }
      format.json { render :json => Hash[:status => @status, :message => @message, :growls => @growls].to_json }
    end
  end

  # PUT /plans/remove/1
  def remove
    @location = Location.find(params[:location_id])
    @user     = current_user

    begin
      @locationship = @user.locationships.find_location_id(@location.id)
      @locationship.try(:decrement!, :planned_checkins)
    rescue Exception => e
      # @location not planned
    end
  
    respond_with(@location) do |format|
      format.html { redirect_back_to(root_path) and return }
    end
  end

end
