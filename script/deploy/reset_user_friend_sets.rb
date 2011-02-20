#!/usr/bin/env ruby
require File.expand_path(File.join(File.dirname(__FILE__), '../..', 'config', 'environment'))

# find all members, and reset friend sets
updated = 0
User.member.each do |user|
  FriendshipWorker.update_friend_set("user_id" => user.id)
  updated += 1
end

puts "#{Time.now}: updated #{updated} user friend sets"
