require File.expand_path('config/environment.rb')

class Facebook < Thor

  desc "user", "show user --fbid facebook info"
  method_options :fbid => nil
  def user
    fbid  = options[:fbid]
    user  = User.find_by_facebook_id(fbid)

    if user.blank?
      puts "[error] invalid user facebook id #{fbid}"
      exit
    end

    # find oauth from user or a friend
    oauth = user.find_facebook_oauth(:friend => true)

    if oauth.blank?
      puts "[error] user #{user.handle} missing facebook oauth token"
      exit
    end

    puts "#{Time.now}: finding user '#{user.handle}' facebook info"

    client  = FacebookClient.new(oauth.access_token)
    data    = client.user(fbid)
    puts data.inspect
    # data.each do |like|
    #   puts like.inspect
    # end
  end

  desc "events", "show user --handle facebook events"
  method_options :handle => nil
  def events
    handle  = options[:handle]
    user    = User.find_by_handle(handle)
    limit   = 100

    if user.blank?
      puts "[error] invalid user handle #{handle}"
      return -1
    end

    # find oauth
    oauth = user.facebook_oauth
    if oauth.blank?
      puts "[error] user #{user.handle} missing facebook oauth token"
      return -1
    end

    puts "#{Time.now}: finding user '#{user.handle}' facebook events"

    client  = FacebookClient.new(oauth.access_token)
    data    = client.events(:limit => limit)
    puts data.inspect
  end

  desc "feed", "show user --handle facebook feed"
  method_options :handle => nil
  def feed
    handle  = options[:handle]
    user    = User.find_by_handle(handle)
    limit   = 100

    if user.blank?
      puts "[error] invalid user handle #{handle}"
      return -1
    end

    # find oauth
    oauth = user.facebook_oauth
    if oauth.blank?
      puts "[error] user #{user.handle} missing facebook oauth token"
      return -1
    end

    puts "#{Time.now}: finding user '#{user.handle}' facebook feed"

    client    = FacebookClient.new(oauth.access_token)
    response  = client.feed(:limit => limit)
    response['data'].each do |object|
      puts object.inspect
    end
  end
end