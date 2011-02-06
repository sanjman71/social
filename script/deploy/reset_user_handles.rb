#!/usr/bin/env ruby
require File.expand_path(File.join(File.dirname(__FILE__), '../..', 'config', 'environment'))

# find all non-members, and reset user handles
updated = 0
User.non_member.each do |user|
  new_handle = User.handle_from_full_name(user.handle)
  if new_handle != user.handle
    # change handle
    user.handle = new_handle
    user.save
    updated += 1
  end
end

puts "#{Time.now}: updated #{updated} user handles"
