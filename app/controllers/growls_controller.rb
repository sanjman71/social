class GrowlsController < ApplicationController
  # before_filter :authenticate_user!

  # GET /growls
  def index
    # send test message
    @growls = [{:message => 'growl message', :timeout => 1000}]

    respond_to do |format|
      format.json { render :json => @growls.to_json }
    end
  end

end