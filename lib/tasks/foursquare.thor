require File.expand_path('config/environment.rb')
require 'ruby-debug'

class Foursquare < Thor

  desc "poll", "check recent foursquare checkins for user --handle or --user, import if --import=1"
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
    oauth = user.foursquare_oauth

    if oauth.blank?
      puts "[error] user #{user.handle} missing oauth"
      return -1
    end

    options   = {'limit' => limit}
    client    = FoursquareApi.new(oauth.access_token_secret.present? ? oauth.access_token_secret : oauth.access_token)
    response  = client.user_checkins('self', options)

    # check response
    if response['meta']['code'] != 200
      puts "[error] #{response['meta']}"
      return -1
    end

    checkins  = response['response']['checkins']
    count     = checkins['count']
    items     = checkins['items']
    items.each do |checkin_hash|
      if import == 1
        puts '*** importing'
        FoursquareWorker.import_checkin(user, checkin_hash)
      else
        puts checkin_hash.inspect
      end
    end
  end

end