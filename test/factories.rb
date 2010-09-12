require 'factory_girl'

Factory.define :us, :class => :Country do |o|
  o.name        "United States"
  o.code        "US"
end

Factory.define :canada, :class => :Country do |o|
  o.name        "Canada"
  o.code        "CA"
end

Factory.define :country do |o|
  o.name        "United States"
  o.code        "US"
end

Factory.define :il, :class => :State do |o|
  o.name        "Illinois"
  o.code        "IL"
end

Factory.define :ny, :class => :State do |o|
  o.name        "New York"
  o.code        "NY"
end

Factory.define :ma, :class => :State do |o|
  o.name        "Massachusetts"
  o.code        "MA"
end

Factory.define :ontario, :class => :State do |o|
  o.name        "Ontario"
  o.code        "ON"
end

Factory.define :state do |o|
  o.name        "Illinois"
  o.code        "IL"
end

Factory.define :chicago, :class => :City do |o|
  o.name        "Chicago"
end

Factory.define :toronto, :class => :City do |o|
  o.name        "Toronto"
end

Factory.define :city do |o|
  o.name        "City Name"
end

Factory.define :zip do |o|
  o.name        "60654"
  o.state       { |o| Factory(:state) }
end

Factory.define :neighborhood do |o|
  o.name        "River North"
  o.city        { |o| Factory(:city) }
end

Factory.define :timezone do |o|
  o.name            "UTC"
  o.utc_offset      0
  o.utc_dst_offset  0
end

Factory.define :timezone_chicago, :class => :Timezone do |o|
  o.name            "America/Chicago"
  o.utc_offset      -21600
  o.utc_dst_offset  -18000
end

Factory.define :user do |u|
  u.name                  { |s| Factory.next :user_name }
  u.handle                { |s| Factory.next :user_handle }
  u.password              "secret"
  u.password_confirmation "secret"
  u.state                 "active"    # always create users in active state
end

Factory.define :location do |o|
  o.country   { |o| Factory(:country) }
  o.state     { |o| Factory(:state) }
  o.city      { |o| Factory(:city) }
  o.zip       { |o| Factory(:zip) }
end

Factory.define :company do |o|
  o.name        { |s| Factory.next :company_name }
  o.time_zone   "UTC"
end

Factory.sequence :user_name do |n|
  "User #{n}"
end

Factory.sequence :user_handle do |n|
  "user#{n}"
end

Factory.sequence :user_email do |n|
  "user#{n}@email.com"
end

Factory.sequence :company_name do |n|
  "Company #{n}"
end

Factory.sequence :source_id do |n|
  n
end
