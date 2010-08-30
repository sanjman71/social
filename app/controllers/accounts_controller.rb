class AccountsController < ApplicationController
  before_filter :authenticate_user!

  # GET /accounts
  def index
    @oauth_hash = current_user.oauths.inject(Hash[]) do |hash, oauth|
      hash[oauth.name] = oauth
      hash
    end
  end

  # DELETE /accounts/foursquare/unlink
  def unlink
    @service  = params[:service]
    @oauth    = current_user.oauths.where(:name => @service).first
    @oauth.try(:destroy)
    flash[:notice] = "#{@service.titleize} unlinked from account"
    redirect_to(accounts_path) and return
  end
end