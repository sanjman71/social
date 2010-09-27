class HomeController < ApplicationController
  skip_before_filter :check_beta, :only => [:beta, :ping]

  # GET /
  def index
    # find all user's oauths
    @oauth = current_user.try(:oauths)

    if user_signed_in?
      # find user profiles
      @profiles   = current_user.search_radius(:limit => 20, :miles => current_user.radius, :klass => User)
      # find nearby locations
      @locations  = current_user.search_radius(:limit => 20, :miles => current_user.radius, :klass => Location)
    end
  end

  # GET /beta
  # POST /beta
  def beta
    if request.post?
      case params[:code].downcase
      when BETA_CODE
        session[:beta] = 1
        redirect_to(root_path) and return
      else
        session[:beta] = 0
        flash[:notice] = "Invalid access code"
        redirect_to(beta_path) and return
      end
    end
  end

  # GET /ping
  def ping
    # touch the database
    @user = User.first
    head(:ok)
  end

end