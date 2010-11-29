#!/usr/bin/env ruby
require File.expand_path(File.join(File.dirname(__FILE__), '../..', 'config', 'environment'))

# find all users with oauth tokens
User.with_oauths.each do |user|
  user = User.find(user.id)
  puts "#{Time.now}: importing upto #{Friendship.limit} friends for user #{user.handle}"
  FacebookFriend.delay.async_import_friends(user)
end