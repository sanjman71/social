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

  # get list of friends
  # e.g. {"data"=>[{"name"=>"Praveen Shanbhag", "id"=>"33630"}, {"name"=>"Alli Brian", "id"=>"208675"},
  #                {"name"=>"Adam Marchick", "id"=>"620186040"}]}
  def friends(options={})
    options.merge!(:access_token => @token)
    self.class.get("https://graph.facebook.com/me/friends", :query => options)
  end

  def place(id, options={})
    self.class.get("https://graph.facebook.com/#{id}", :query => options)
  end

  # search for recent check-ins for an authorized user and his or her friends
  def search_checkins(options={})
    options.merge!(:access_token => @token, :type => 'checkin')
    self.class.get("https://graph.facebook.com/search", :query => options)
  end
end