class HomeController < ApplicationController
  
  def index
    @oauth      = current_user.try(:oauths)
    @locations  = Location.limit(20)
  end

end