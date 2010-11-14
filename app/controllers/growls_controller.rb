class GrowlsController < ApplicationController
  # before_filter :authenticate_user!

  # GET /growls
  def index
    # check flash for growl messages
    if flash[:growls]
      # use flash message and discard
      @growls = flash[:growls]
      flash.discard(:growls)
    else
      @growls = []
    end

    respond_to do |format|
      format.json { render :json => Hash[:growls => @growls].to_json }
    end
  end

end