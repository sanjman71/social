#!/usr/bin/env ruby
require File.expand_path(File.join(File.dirname(__FILE__), '../..', 'config', 'environment'))

puts "#{Time.now}: removing all member user badgings"
# remove all member user badgings
User.member.each do |user|
  user.badgings.each { |b| b.destroy }
end

puts "#{Time.now}: rebuilding all member user badges"
# rebuild all member user badges
User.member.each do |user|
  user.async_add_badges
end

puts "#{Time.now}: completed"
