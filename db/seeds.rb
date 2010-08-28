# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)

# countries
@us = Country.create(:name => "United States", :code => "US")
puts "#{Time.now}: initialized countries"

# states
columns = [:id, :name, :code, :country_id, :lat, :lng]
file    = "#{Rails.root}/data/states.txt"
puts "#{Time.now}: importing states ... parsing file #{file}"
File.open(file).lines.each do |row|
  id, name, code, lat, lng = row.strip.split(',')
  @us.states.create(:name => name, :code => code, :lat => lat.to_f, :lng => lng.to_f)
end
puts "#{Time.now}: initialized #{State.count} states"

# cities
@il = @us.states.find_by_code('IL')
@chicago = @il.cities.create(:name => 'Chicago', :lat => 41.879535, :lng => -87.624333)

# locations - coffee, pizza, bar
[
 # coffee
 {"id"=>108207, "name"=>"Starbucks - State St and Ohio St",
   "primarycategory"=>{"id"=>79049, "fullpathname"=>"Food:Cafe", "nodename"=>"Cafe", "iconurl"=>"http://foursquare.com/img/categories/food/cafe.png"},
   "address"=>"600 N State St", "crossstreet"=>"State St and Ohio St", "city"=>"Chicago", "state"=>"IL", "zip"=>"60654",
   "geolat"=>41.892483, "geolong"=>-87.6281306, "stats"=>{"herenow"=>"0"}, "phone"=>"3125730033", "distance"=>506},
 {"id"=>564552, "name"=>"Lavazza at French Market",
  "primarycategory"=>{"id"=>79052, "fullpathname"=>"Food:Coffee Shop", "nodename"=>"Coffee Shop", "iconurl"=>"http://foursquare.com/img/categories/food/coffeeshop.png"},
  "address"=>"131 N. Clinton St.", "crossstreet"=>"at Randolph St.", "city"=>"Chicago", "state"=>"IL", "zip"=>"60606",
  "geolat"=>41.8840864, "geolong"=>-87.6412261, "stats"=>{"herenow"=>"0"}, "distance"=>1602},
 {"id"=>135721, "name"=>"Argo Tea on Rush",
  "primarycategory"=>{"id"=>79107, "fullpathname"=>"Food:Tea Room", "nodename"=>"Tea Room", "iconurl"=>"http://foursquare.com/img/categories/food/tearoom.png"},
  "address"=>"819 N Rush St", "crossstreet"=>"Rush & Pearson", "city"=>"Chicago", "state"=>"IL", "zip"=>"60611",
  "geolat"=>41.897146, "geolong"=>-87.625386, "stats"=>{"herenow"=>"0"}, "distance"=>490},
 # pizza
 {"id"=>153168, "name"=>"Lou Malnati's Pizzeria",
  "primarycategory"=>{"id"=>79081, "fullpathname"=>"Food:Pizza", "nodename"=>"Pizza", "iconurl"=>"http://foursquare.com/img/categories/food/pizza.png"},
  "address"=>"439 N. Wells St.", "crossstreet"=>"Hubbard St.", "city"=>"Chicago", "state"=>"IL", "zip"=>"60654",
  "geolat"=>41.890344, "geolong"=>-87.633742, "stats"=>{"herenow"=>"0"}, "distance"=>706},
 {"id"=>45048, "name"=>"Gino's East Pizza",
  "primarycategory"=>{"id"=>79081, "fullpathname"=>"Food:Pizza", "nodename"=>"Pizza", "iconurl"=>"http://foursquare.com/img/categories/food/pizza.png"},
  "address"=>"162 E Superior St", "city"=>"Chicago", "state"=>"IL", "zip"=>"60611", "geolat"=>41.8962, "geolong"=>-87.6233,
  "stats"=>{"herenow"=>"0"}, "phone"=>"3122663337", "distance"=>656}, 
 {"id"=>135735, "name"=>"Giordano's",
  "primarycategory"=>{"id"=>79081, "fullpathname"=>"Food:Pizza", "nodename"=>"Pizza", "iconurl"=>"http://foursquare.com/img/categories/food/pizza.png"},
  "address"=>"730 N. Rush St.", "crossstreet"=>"at Superior St", "city"=>"Chicago", "state"=>"IL", "zip"=>"60611",
  "geolat"=>41.895649, "geolong"=>-87.625473, "stats"=>{"herenow"=>"0"}, "phone"=>"3129510747", "distance"=>483},
 # bar
 {"id"=>684215, "name"=>"Streeter's Tavern",
  "primarycategory"=>{"id"=>79158, "fullpathname"=>"Nightlife:Dive Bar", "nodename"=>"Dive Bar", "iconurl"=>"http://foursquare.com/img/categories/nightlife/default.png"},
  "address"=>"50 E. Chicago Ave.", "crossstreet"=>"at Wabash", "city"=>"Chicago", "state"=>"IL", "zip"=>"60611", 
  "geolat"=>41.8967385, "geolong"=>-87.6263327, "stats"=>{"herenow"=>"0"}, "phone"=>"3129445206", "distance"=>406},
 {"id"=>12531, "name"=>"Hopleaf Bar",
  "primarycategory"=>{"id"=>79153, "fullpathname"=>"Nightlife:Bar", "nodename"=>"Bar", "iconurl"=>"http://foursquare.com/img/categories/nightlife/default.png"},
  "address"=>"5148 N. Clark St", "crossstreet"=>"at Foster Ave", "city"=>"Chicago", "state"=>"IL", "zip"=>"60640",
  "geolat"=>41.975814, "geolong"=>-87.668739, "stats"=>{"herenow"=>"0"}, "phone"=>"7733349851", "distance"=>9369},
 {"id"=>88928, "name"=>"The Beer Bistro",
  "primarycategory"=>{"id"=>79153, "fullpathname"=>"Nightlife:Bar", "nodename"=>"Bar", "iconurl"=>"http://foursquare.com/img/categories/nightlife/default.png"},
  "address"=>"1061 W. Madison", "city"=>"Chicago", "state"=>"IL", "zip"=>"60607", "geolat"=>41.8814, "geolong"=>-87.6543,
  "stats"=>{"herenow"=>"0"}, "distance"=>2539},
 # restaurant
 {"id"=>76668, "name"=>"Paramount Room",
   "primarycategory"=>{"id"=>79155, "fullpathname"=>"Nightlife:Brewery / Microbrewery", "nodename"=>"Brewery / Microbrewery", "iconurl"=>"http://foursquare.com/img/categories/nightlife/brewery.png"},
   "address"=>"415 North Milwaukee", "crossstreet"=>"Kinzie and Milwaukee", "city"=>"Chicago", "state"=>"IL", "geolat"=>41.889663,
   "geolong"=>-87.644823, "stats"=>{"herenow"=>"0"}, "twitter"=>"paramountroom", "distance"=>1354},
 {"id"=>1207640, "name"=>"Dos Diablos",
  "primarycategory"=>{"id"=>79076, "fullpathname"=>"Food:Mexican", "nodename"=>"Mexican", "iconurl"=>"http://foursquare.com/img/categories/food/default.png"},
  "address"=>"15 W Hubbard", "crossstreet"=>"State", "city"=>"Chicago", "state"=>"Illinois", "geolat"=>41.8900428,
  "geolong"=>-87.6286873, "stats"=>{"herenow"=>"0"}, "distance"=>738},
 {"id"=>131820, "name"=>"Volare",
   "primarycategory"=>{"id"=>79069, "fullpathname"=>"Food:Italian", "nodename"=>"Italian", "iconurl"=>"http://foursquare.com/img/categories/food/default.png"},
   "address"=>"201 E Grand Ave", "city"=>"Chicago", "state"=>"IL", "geolat"=>41.891518, "geolong"=>-87.622492, 
   "stats"=>{"herenow"=>"0"}, "distance"=>904}
].each do |hash|
  LocationImport.import_foursquare_venue(hash)
end
puts "#{Time.now}: imported #{Location.count} locations"

# users
[{"handle" => "chicago_coffee_gal", "password" => 'coffee', 'password_confirmation' => 'secret'},
 {"handle" => "chicago_coffee_guy", "password" => 'coffee', 'password_confirmation' => 'secret'},
 {"handle" => "chicago_pizza_gal", "password" => 'pizza', 'password_confirmation' => 'secret'},
 {"handle" => "chicago_pizza_guy", "password" => 'pizza', 'password_confirmation' => 'secret'},
 {"handle" => "chicago_bar_gal", "password" => 'bar', 'password_confirmation' => 'secret'},
 {"handle" => "chicago_bar_guy", "password" => 'bar', 'password_confirmation' => 'secret'},
 {"handle" => "chicago_foodie_gal", "password" => 'foodie', 'password_confirmation' => 'secret'},
 {"handle" => "chicago_foodie_guy", "password" => 'foodie', 'password_confirmation' => 'secret'}
].each do |hash|
  User.create(hash)
end
puts "#{Time.now}: imported #{User.count} users"

# checkins
@offset = 0
['coffee', 'pizza', 'bar', 'foodie'].each do |s|
  @gal = User.find_by_handle("chicago_#{s}_gal")
  @guy = User.find_by_handle("chicago_#{s}_guy")
  [@gal, @guy].each do |user|
    Location.limit(3).offset(@offset).each do |location|
      user.checkins.create(:location_id => location.id, :checkin_at => Time.zone.now - 3.days,
                           :source_id => location.location_source.id, :source_type => 'fs')
    end
  end
  @offset += 3
end
puts "#{Time.now}: imported #{Checkin.count} checkins"

