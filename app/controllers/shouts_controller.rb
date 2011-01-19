class ShoutsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_location, :only => [:add]
  respond_to    :html, :json

  # GET /shouts
  def index
    @user       = current_user
    @shouts     = @user.shouts
  end

  # PUT /shouts/add
  # PUT /shouts/add/1
  def add
    # @location initialized in before filter

    begin
      # set user to current user
      @user   = current_user
      # create shout
      @text   = params[:text]
      @shout  = @user.shouts.create!(:location => @location, :text => @text)
      # add flash message
      flash[:notice] = "We added your shout for #{@location.name}"
      # set status
      @status   = 'ok'
    rescue Exception => e
      # @location already planned
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