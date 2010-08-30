require 'httparty'

class FacebookClient
  
  include HTTParty
  format :json
  # default_params :access_token => @token

  def initialize(token)
    @token = token
  end

  # get basic information about the current user
  def me
    self.class.get("https://graph.facebook.com/me", :query => {:access_token => @token})
  end

  def picture(id)
    self.class.get("https://graph.facebook.com/#{id}/picture", :query => {:access_token => @token})
  end

  # paging options:
  # - limit, offset
  # - until, since - e.g. until=yesterday, since=2010-02-01T120000
  def checkins(id, options={})
    options.merge!(:access_token => @token)
    self.class.get("https://graph.facebook.com/#{id}/checkins", :query => options)
  end
end