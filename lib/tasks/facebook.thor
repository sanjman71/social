require File.expand_path('config/environment.rb')
require 'ruby-debug'

class Facebook < Thor

  desc "poll", "check recent facebook checkins for user --handle or --user, import if --import=1"
  method_options :handle => nil
  method_options :user => nil
  method_options :limit => nil
  method_options :import => nil
  def poll
    handle  = options[:handle]
    user_id = options[:user]
    limit   = options[:limit] ? options[:limit].to_i : 1
    import  = options[:import].to_i

    if handle.blank? and user_id.blank?
      puts "missing handle or user"
      return
    end

    user  = handle.present? ? User.find_by_handle!(handle) : User.find_by_id(user_id)
    oauth = user.facebook_oauth

    if oauth.blank?
      puts "[error] user #{user.handle} missing oauth"
      return -1
    end

    options   = {'limit' => limit, 'since' => nil}
    client    = FacebookClient.new(oauth.access_token)
    response  = client.checkins(user.facebook_id, options)

    # check response
    if response['error']
      puts "[error] #{response['error']}"
      return -1
    end

    checkins  = response['data']
    checkins.each do |checkin_hash|
      if import == 1
        puts '*** importing'
        FacebookWorker.import_checkin(user, checkin_hash)
      else
        puts checkin_hash.inspect
      end
    end
  end

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