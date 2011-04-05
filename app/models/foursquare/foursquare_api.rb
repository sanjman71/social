require 'httparty'

class FoursquareApi
  
  include HTTParty
  format :json

  def initialize(token)
    @token = token
  end

  # list of recent checkins by friends
  def checkins_recent(params={})
    self.class.get("https://api.foursquare.com/v2/checkins/recent", :query=>params)
  end

  # search specials
  # auth: yes
  # parameters:
  # ll => '44.3,37.2' (latitude and longitude of location)
  def specials_search(params={})
    self.class.get("https://api.foursquare.com/v2/specials/search", :query=>params)
  end

  # get history of user checkins
  # user_id: 'self'
  # limit: 100 (returns up to 500)
  # offset: 100 (page through results)
  # afterTimestamp: 1279044824
  # beforeTimestamp: 1279044824
  def user_checkins(user_id, params={})
    params.merge!(:oauth_token => @token)
    self.class.get("https://api.foursquare.com/v2/users/#{user_id}/checkins", :query=>params)
  end

  # get list of all venues visited by the specified user, along with how many visits and when they were last there
  # user_id: 'self'
  def user_venuehistory(user_id, params={})
    params.merge!(:oauth_token => @token)
    self.class.get("https://api.foursquare.com/v2/users/#{user_id}/venuehistory", :query=>params)
  end

  # search venues
  # auth: no, but requires client_id and client_secret
  # parameters:
  # ll => '44.3,37.2' (latitude and longitude of location)
  # query => 'pizza'
  # limit => 10 (return up to 50)
  def venues_search(params={})
    self.class.get("https://api.foursquare.com/v2/venues/search", :query=>params)
  end

  # return venue detail
  # auth: no, but use it anyway
  # if authenticated, also returns info about who is here now
  def venues_detail(id)
    params = {:oauth_token => @token}
    self.class.get("https://api.foursquare.com/v2/venues/#{id}", :query=>params)
  end
end