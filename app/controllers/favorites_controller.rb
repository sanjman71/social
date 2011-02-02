class FavoritesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_location, :only => [:add]
  respond_to    :html, :json

  # PUT /favorites/add
  # PUT /favorites/add/1
  def add
    # @location initialized in before filter

    begin
      # set user to current user
      @user = current_user
      # send message
      Resque.enqueue(CheckinMailerWorker, :newbie_favorite_added, 'user_id' => @user.id, 'location_id' => @location.id)
      # add flash message
      flash[:notice] = "We added #{@location.name} to your favorites"
      # set status
      @status = 'ok'
    rescue Exception => e
      @status   = 'error'
      @message  = e.message
    end

    # set redirect path
    @redirect_to = redirect_back_path(root_path)

    respond_with(@location) do |format|
      format.html { redirect_back_to(@redirect_to) and return }
      format.js { render(:update) { |page| page.redirect_to(@redirect_to) } }
      format.json { render :json => Hash[:status => @status, :message => @message, :growls => @growls].to_json }
    end
  end

end
