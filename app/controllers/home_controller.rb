class HomeController < ApplicationController
  
  def index
    @oauth = current_user.try(:oauths)
  end

end