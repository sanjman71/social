#!/usr/bin/env ruby
require File.expand_path(File.join(File.dirname(__FILE__), '../..', 'config', 'environment'))

# args - 'members'|'users'
argv0 = ARGV[0]

case argv0
when 'members'
  member = 1
when 'users'
  member = 0
else
  puts "usage: members|users"
  exit
end

# find users, and add data from facebook profile
updated = 0
User.where(:member => member).each do |user|
  oauth = user.find_facebook_oauth(:friend => true)
  next if oauth.blank?

  # track changes to each user
  changes = 0

  begin
    rg      = RestGraph.new(:access_token => oauth.access_token)
    query   = 'SELECT birthday_date,email,name FROM user WHERE uid="' + user.facebook_id + '"'
    data    = rg.fql(query)
    hash    = data.first
    # puts "[user:#{user.id}] #{user.handle}:#{hash}"
    email   = hash['email']
    name    = hash['name']
    bdate   = hash['birthday_date']
    # check user, handle, email, bdate
    handle  = User.handle_from_full_name(name)
    if name != user.name
      puts "[user:#{user.id}] changing name to #{name}"
      user.name = name
      changes  += 1
    end
    if handle != user.handle
      puts "[user:#{user.id}] changing handle to #{handle}"
      user.handle = handle
      changes    += 1
    end
    if user.email_addresses_count == 0 and email.present?
      puts "[user:#{user.id}] setting email to #{email}"
      user.email_addresses.create(:address => email)
      changes += 1
    end
    if bdate.present? and bdate.match(/\d{4,4}$/) and user.birthdate.blank?
      puts "[user:#{user.id}] setting birthdate to #{bdate}"
      user.birthdate = Chronic.parse(bdate).to_date
      changes       += 1
    end
    if changes > 0
      # save changes and increment counter
      user.save
      updated += 1
    end
  rescue Exception => e
    puts "[error] #{e.message}"
  end
end

puts "#{Time.now}: updated #{updated} members"
