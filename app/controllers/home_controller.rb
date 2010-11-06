class HomeController < ApplicationController
  skip_before_filter :check_beta, :only => [:beta, :ping]

  # GET /
  def index
    if user_signed_in?
      # find matching checkins
      @stream       = current_stream
      @method       = "search_#{@stream}_checkins"
      @checkins     = current_user.send(@method, :limit => checkins_start_count,
                                                 :miles => current_user.radius,
                                                 :order => [:sort_similar_locations])
      # mark checkins from me and friends
      
      @max_objects  = checkins_end_count
    end

    # check for growl messages
    @growls = params[:growls].to_i
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

  # PUT /stream?name='daters'
  def stream
    # change the user's stream
    session[:current_stream] = params[:name]
    redirect_to root_path and return
  end

  protected
  
  def checkins_start_count
    3
  end

  def checkins_end_count
    8
  end

  def current_stream
    session[:current_stream] ||= 'my-stream'
    session[:current_stream].match(/([a-z]+)-.+/).try(:[], 1)
  end

end