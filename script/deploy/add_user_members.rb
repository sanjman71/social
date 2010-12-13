#!/usr/bin/env ruby
require File.expand_path(File.join(File.dirname(__FILE__), '../..', 'config', 'environment'))

# find all users with oauth tokens
User.with_oauths.each do |user|
  user = User.find(user.id)
  if !user.member?
    user.member = true
    user.save
    puts "#{Time.now}: set member flag on user #{user.handle} "
  end
end

# find seed users
users = User.where(:handle.matches % "%bar_gal" | :handle.matches % "%bar_guy" |
                   :handle.matches % "%coffee_gal" | :handle.matches % "%coffee_guy" |
                   :handle.matches % "%foodie_gal" | :handle.matches % "%foodie_guy" |
                   :handle.matches % "%pizza_gal" | :handle.matches % "%pizza_guy")
users.each do |user|
  if !user.member?
    user.member = true
    user.save
    puts "#{Time.now}: set member flag on user #{user.handle} "
  end
end