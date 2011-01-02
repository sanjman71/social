class BetaController < ApplicationController
  skip_before_filter  :check_beta

  # GET /beta
  # POST /beta
  def show
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

end