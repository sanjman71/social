class CheckinsController < ApplicationController
  
  def index
    @checkins = current_user.checkins
  end

end