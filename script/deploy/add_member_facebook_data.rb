#!/usr/bin/env ruby
require File.expand_path(File.join(File.dirname(__FILE__), '../..', 'config', 'environment'))

# find all members, and add data from facebook profile
updated = 0
User.member.each do |user|
  # find members with no email address
  if user.email_addresses_count == 0
    # puts user.inspect
    oauth = user.find_facebook_oauth
    next if oauth.blank?

    begin
      rg      = RestGraph.new(:access_token => oauth.access_token)
      query   = 'SELECT birthday_date,email,name FROM user WHERE uid="' + user.facebook_id + '"'
      data    = rg.fql(query)
      hash    = data.first
      puts "[user:#{user.id}] #{user.handle}:#{hash}"
      email   = hash['email']
      name    = hash['name']
      bdate   = hash['birthday_date']
      # check handle
      handle  = User.handle_from_full_name(name)
      if handle != user.handle
        puts "[user:#{user.id}] changing handle to #{handle}"
        user.handle = handle
      end
      if email.present? and email != user.email_address
        puts "[user:#{user.id}] setting email to #{email}"
        user.email_addresses.create(:address => email)
      end
      if bdate.present? and user.birthdate.blank?
        puts "[user:#{user.id}] setting birthdate to #{bdate}"
        user.birthdate = Chronic.parse(bdate).to_date
      end
      user.save
      updated += 1
    rescue Exception => e
      puts "[error] #{e.message}"
    end
  end
end

puts "#{Time.now}: updated #{updated} members"
