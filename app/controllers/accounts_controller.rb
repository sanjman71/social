class AccountsController < ApplicationController
  before_filter :authenticate_user!

  
  def index
    @oauth_hash = current_user.oauths.inject(Hash[]) do |hash, oauth|
      hash[oauth.name] = oauth
      hash
    end
  end

end