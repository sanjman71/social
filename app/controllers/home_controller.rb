class HomeController < ApplicationController
  skip_before_filter :check_beta, :only => [:beta, :ping]

  # GET /
  def index
    @oauth      = current_user.try(:oauths)
    @locations  = Location.limit(50).order('RAND()')
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