require File.expand_path('config/environment.rb')

class Facebook < Thor
  
  desc "info", "show user [handle] facebook info"
  method_options :handle => nil
  def info
    handle  = options[:handle]
    user    = User.find_by_handle(handle)

    if user.blank?
      puts "[error] invalid user handle #{hanadle}"
      return -1
    end

    # find oauth
    oauth = user.oauths.facebook.first
    if oauth.blank?
      puts "[error] user #{user.handle} missing facebook oauth token"
      return -1
    end

    puts "#{Time.now}: finding user '#{user.handle}' facebook info"

    client    = FacebookClient.new(oauth.access_token)
    data      = client.me
    puts data.inspect
    # data.each do |like|
    #   puts like.inspect
    # end
  end
end