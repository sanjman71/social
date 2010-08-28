class OauthController < ApplicationController
  # prepend_before_filter :require_no_authentication, :only => [:initiate, :callback]
  
  # GET /oauth/foursquare/initiate
  def initiate
    # generate request token
    @service        = params[:service]
    @consumer       = User.foursquare_oauth_consumer    
    @request_token  = @consumer.get_request_token(:oauth_callback => "http://localhost:5001/oauth/#{@service}/callback")
    # cache request token and secret
    session[:request_token] = @request_token
    redirect_to(@request_token.authorize_url)
  end

  # GET /oauth/foursquare/callback
  def callback
    debugger
    # get cached request token
    @request_token  = session[:request_token]
    # use oauth verifier to build access token
    @access_token   = @request_token.get_access_token(:oauth_verifier => params[:oauth_verifier])
    # check if user is trying to create their account or link to their account using oauth
    @create_account = current_user.blank?
    # set user's oauth token, and create user if necessary
    @method = "find_for_#{params[:service]}_oauth"
    @user   = User.send(@method, @access_token, current_user)
    # sign in user
    sign_in(@user)
    if @create_account
      flash[:notice] = "Successfully created account and linked it to #{params[:service]}"
    else
      flash[:notice] = "Successly logged in as #{@user.handle}"
    end
    # note: if we were going to use warden to login, we might use it like this
    # resource = warden.authenticate!(:simple, :scope => :user)
    redirect_to(root_path) and return
  rescue Exception => e
    logger.debug("oauth #{params[:service]} callback error: #{e.message}" )
    flash[:error] = "Oauth error: #{e.message}"
    redirect_to(login_path) and return
  end
  
end