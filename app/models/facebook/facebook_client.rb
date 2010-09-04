require 'httparty'

class FacebookClient
  
  include HTTParty
  format :json
  # default_params :access_token => @token

  def initialize(token)
    @token = token
  end

  # get basic information about the current user
  # e.g. {"id": "633015812", "name": "Sanjay Kapoor", "first_name": "Sanjay", "last_name": "Kapoor",
  #       "link": "http://www.facebook.com/sanjman71", "gender": "male", "email": "sanjay@jarna.com", "timezone": -5,
  #       "locale": "en_US", "verified": true, "updated_time": "2009-07-16T03:50:41+0000" }
  def me
    self.class.get("https://graph.facebook.com/me", :query => {:access_token => @token})
  end

  def picture(id)
    self.class.get("https://graph.facebook.com/#{id}/picture", :query => {:access_token => @token})
  end

  # paging options:
  # - limit, offset
  # - until, since - e.g. until=yesterday, since=2010-02-01T120000, since=September 04, 2010 at 09:26 AM
  def checkins(id, options={})
    options.merge!(:access_token => @token)
    self.class.get("https://graph.facebook.com/#{id}/checkins", :query => options)
  end
end