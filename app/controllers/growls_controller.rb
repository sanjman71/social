class GrowlsController < ApplicationController
  # before_filter :authenticate_user!

  # GET /growls
  def index
    # check flash for growl messages
    @growls = flash[:growls] ? flash[:growls] : []

    respond_to do |format|
      format.json { render :json => Hash[:growls => @growls].to_json }
    end
  end

end