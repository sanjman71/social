class OauthController < ApplicationController
  # prepend_before_filter :require_no_authentication, :only => [:initiate, :callback]
  
  # GET /oauth/foursquare/initiate
  def initiate
    # generate request token
    @service        = params[:service]
    case @service
    when 'foursquare'
      @consumer = User.oauth_consumer_foursquare
    when 'twitter'
      @consumer = User.oauth_consumer_twitter
    else
      raise Exception, "unsupported service #{@service}"
    end
    # build callback url using request host + port
    @host_port      = "http://#{request.host}" + (request.port == 80 ? '' : ":#{request.port}")
    @request_token  = @consumer.get_request_token(:oauth_callback => "#{@host_port}/oauth/#{@service}/callback")
    # cache request token and secret
    session[:request_token] = @request_token
    redirect_to(@request_token.authorize_url)
  rescue Exception => e
    logger.debug("oauth #{params[:service]} initiate error: #{e.message}" )
    flash[:error] = "Oauth error: #{e.message}"
    if user_signed_in?
      redirect_to(root_path) and return
    else
      redirect_to(login_path) and return
    end
  end

  # GET /oauth/foursquare/callback
  def callback
    @service        = params[:service]
    # get cached request token
    @request_token  = session[:request_token]
    # use oauth verifier to build access token
    @access_token   = @request_token.get_access_token(:oauth_verifier => params[:oauth_verifier])
    # set user's oauth token, and create user if necessary
    @method = "find_for_#{params[:service]}_oauth"
    @user   = User.send(@method, @access_token, current_user)
    if !user_signed_in?
      @redirect_path = root_path
      flash[:notice] = "Successfully authenticated using #{@service} account"
    else
      @redirect_path = root_path
      flash[:notice] = "Successly linked #{@service} account"
    end
    # sign in user
    sign_in(@user)
    # note: if we were going to use warden to login, we might use it like this
    # resource = warden.authenticate!(:simple, :scope => :user)
    redirect_to(@redirect_path) and return
  rescue Exception => e
    logger.debug("oauth #{params[:service]} callback error: #{e.message}" )
    flash[:error] = "Oauth error: #{e.message}"
    redirect_to(@redirect_path || root_path) and return
  end
  
end