class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :check_beta

  # default application layout
  layout 'application'
  
  protected
  
  # check that user has signed up for the beta
  def check_beta
    if session[:beta].to_i != 1
      redirect_to(beta_path) and return
    end
  end

end
