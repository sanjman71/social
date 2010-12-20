class OauthController < Devise::OmniauthCallbacksController

  # GET /users/auth/facebook/callback?code=1234567
  def facebook
    callback('facebook')
  end

  # GET /users/auth/facebook/callback?oauth_token=1234567"
  def foursquare
    callback('foursquare')
  end

  # GET /users/auth/twitter/callback
  def twitter
    callback('twitter')
  end

  # GET /users/auth/outlately/callback?handle=chicago_guy
  # note: used for testing
  def outlately
    @handle = params[:handle]
    @user   = User.find_by_handle(@handle)
    
    if user_signed_in?
      # user already signed in
      flash[:error] = "User already signed in"
    elsif @user.blank?
      flash[:error] = "Invalid user"
    elsif @user.present? and @user.oauths.any?
      flash[:error] = "User has a valid oauth"
    else
      sign_in(@user)
      flash[:notice] = "Welcome back #{@user.handle}"
    end

    redirect_to root_path and return
  end

  # GET /users/auth/outlately/callback?handle=chicago_guy
  def failure
    if params[:handle].present?
      outlately
    end
  end

  # GET /oauth/foursquare/initiate
  # def initiate
  #   # generate request token
  #   @service        = params[:service]
  #   case @service
  #   when 'foursquare'
  #     @consumer = User.oauth_consumer_foursquare
  #   when 'twitter'
  #     @consumer = User.oauth_consumer_twitter
  #   else
  #     raise Exception, "unsupported service #{@service}"
  #   end
  #   # build callback url using request host + port
  #   @host_port      = "http://#{request.host}" + (request.port == 80 ? '' : ":#{request.port}")
  #   @request_token  = @consumer.get_request_token(:oauth_callback => "#{@host_port}/oauth/#{@service}/callback")
  #   # cache request token and secret
  #   session[:request_token] = @request_token
  #   redirect_to(@request_token.authorize_url)
  # rescue Exception => e
  #   logger.debug("oauth #{params[:service]} initiate error: #{e.message}" )
  #   flash[:error] = "Oauth error: #{e.message}"
  #   if user_signed_in?
  #     redirect_to(root_path) and return
  #   else
  #     redirect_to(login_path) and return
  #   end
  # end

  # GET /oauth/foursquare/callback
  def callback(service)
    @credentials  = env["omniauth.auth"]['credentials'] rescue {}
    @user_data    = env["omniauth.auth"]['extra']['user_hash'] rescue {}
    @method       = "find_for_#{service}_oauth"
    # set user's oauth token, and create user if necessary
    @user         = User.send(@method, @credentials, @user_data, current_user)

    if !user_signed_in?
      flash[:notice] = "Welcome back #{@user.handle}"
    else
      flash[:notice] = "Successly linked #{service} account"
    end
    # sign in user
    sign_in(@user)
    # note: if we were going to use warden to login, we might use it like this
    # resource = warden.authenticate!(:simple, :scope => :user)
    redirect_to(root_path) and return
  rescue Exception => e
    logger.debug("oauth #{service} callback error: #{e.message}" )
    flash[:error] = "Oauth error: #{e.message}"
    redirect_to(@redirect_path || root_path) and return
  end
  
end