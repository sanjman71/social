class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :check_beta

  # default application layout
  layout 'application'

  # called by devise after a successful user login
  def after_sign_in_path_for(resource_or_scope)
    case resource_or_scope
    when :user, User
      if resource_or_scope.created_recently?(1)
        # allow user to change handle
        edit_user_path(resource_or_scope, :handle => 1)
      else
        # the default post login page
        root_url
      end
    else
      super
    end
  end

  def redirect_back_to(path)
    redirect_to(params[:return_to] || path)
  end

  protected
  
  # check that user has signed up for the beta
  def check_beta
    if session[:beta].to_i != 1
      redirect_to(beta_path) and return
    end
  end

end
