class HomeController < ApplicationController
  
  def index
    @oauth      = current_user.try(:oauths)
    @locations  = Location.limit(50).order('RAND()')
  end

end