#!/usr/bin/env ruby
require File.expand_path(File.join(File.dirname(__FILE__), '../..', 'config', 'environment'))

# find all todos
Locationship.todo_checkins.each do |locship|
  locship.todo_expires_at = locship.todo_at + Locationship.todo_days.days
  locship.save
end

puts "#{Time.now}: updated todos"
