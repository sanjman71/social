#!/usr/bin/env ruby
require File.expand_path(File.join(File.dirname(__FILE__), '../..', 'config', 'environment'))

# find all non-members, and reset user handles
User.non_member.each do |user|
  user.handle = User.handle_from_full_name(user.handle)
  user.save
end

puts "#{Time.now}: updated user handles"
