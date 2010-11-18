# coding: utf-8

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)

# remove log files
system "rm -f #{Rails.root}/log/.*.log"
system "rm -f #{Rails.root}/log/delayed_job.log"
system "rm -f #{Rails.root}/log/outlately.*.log"
puts "#{Time.now}: removed log files"

# countries
@us = Country.create!(:name => "United States", :code => "US")
@ca = Country.create!(:name => "Canada", :code => "CA")

@de = Country.create!(:name => "Germany", :code => "DE")
@es = Country.create!(:name => "Spain", :code => "ES")
@fr = Country.create!(:name => "France", :code => "FR")
@gb = Country.create!(:name => "United Kingdom", :code => "GB")
@ie = Country.create!(:name => "Ireland", :code => "IE")

puts "#{Time.now}: initialized #{Country.count} countries"

# us states
file = "#{Rails.root}/data/us_states.txt"
puts "#{Time.now}: importing us states ... parsing file #{file}"
File.open(file).lines.each do |row|
  id, name, code, lat, lng = row.strip.split(',')
  @us.states.create(:name => name, :code => code, :lat => lat.to_f, :lng => lng.to_f)
end
# canada provinces
file = "#{Rails.root}/data/canada_states.txt"
puts "#{Time.now}: importing canada provinces ... parsing file #{file}"
File.open(file).lines.each do |row|
  name, code, lat, lng = row.strip.split(',')
  @ca.states.create(:name => name, :code => code, :lat => lat.to_f, :lng => lng.to_f)
end
puts "#{Time.now}: initialized #{State.count} states"

# cities
cities = ['Boston', 'Chicago', 'New York', 'San Francisco']
cities.each do |s|
  Locality.resolve(s, :create => true)
end
puts "#{Time.now}: initialized #{City.count} cities"

# badges
Badge.create(:regex => "airport|travel", :name => 'JetSetter')
Badge.create(:regex => "american", :name => 'Meat and Potatoes')
Badge.create(:regex => "bar", :name => 'Booze Hound')
Badge.create(:regex => "coffee|coffee shop", :name => 'Caffeine Junkie')
Badge.create(:regex => "corporate|office", :name => 'Office Space')
Badge.create(:regex => "event space|nightlife", :name => 'Socialite')
Badge.create(:regex => "indian|mexican", :name => 'Adventurous Pallette')
Badge.create(:regex => "shops", :name => 'Shopaholic')
puts "#{Time.now}: imported #{Badge.count} badges"

# pics
@girl_pics = ['http://i972.photobucket.com/albums/ae209/yoshidoll_69/photography/hgfgf.jpg',
              'http://i972.photobucket.com/albums/ae209/yoshidoll_69/photography/10578-815ba9-450-349.jpg',
              'http://i972.photobucket.com/albums/ae209/yoshidoll_69/photography/b215752279.jpg',
              'http://i972.photobucket.com/albums/ae209/yoshidoll_69/scene%20hair/5950259972a11818015567l.jpg',
              'http://i972.photobucket.com/albums/ae209/yoshidoll_69/photography/photo2.jpg'
             ]

@guy_pics = ['http://i972.photobucket.com/albums/ae209/yoshidoll_69/Decorated%20images/9437.jpg',
             'http://i972.photobucket.com/albums/ae209/yoshidoll_69/photography/tumblr_l3iion0YYZ1qzfya1o1_500.jpg'
            ]

# locations - coffee, pizza, bar
[
 # coffee - chicago
 {"id"=>108207, "name"=>"Starbucks - State St and Ohio St",
   "primarycategory"=>{"id"=>79049, "fullpathname"=>"Food:Cafe", "nodename"=>"Cafe", "iconurl"=>"http://foursquare.com/img/categories/food/cafe.png"},
   "address"=>"600 N State St", "crossstreet"=>"State St and Ohio St", "city"=>"Chicago", "state"=>"IL", "zip"=>"60654",
   "lat"=>41.892483, "lng"=>-87.6281306, "stats"=>{"herenow"=>"0"}, "phone"=>"3125730033", "distance"=>506},
 {"id"=>564552, "name"=>"Lavazza at French Market",
  "primarycategory"=>{"id"=>79052, "fullpathname"=>"Food:Coffee Shop", "nodename"=>"Coffee Shop", "iconurl"=>"http://foursquare.com/img/categories/food/coffeeshop.png"},
  "address"=>"131 N. Clinton St.", "crossstreet"=>"at Randolph St.", "city"=>"Chicago", "state"=>"IL", "zip"=>"60606",
  "lat"=>41.8840864, "lng"=>-87.6412261, "stats"=>{"herenow"=>"0"}, "distance"=>1602},
 {"id"=>135721, "name"=>"Argo Tea on Rush",
  "primarycategory"=>{"id"=>79107, "fullpathname"=>"Food:Tea Room", "nodename"=>"Tea Room", "iconurl"=>"http://foursquare.com/img/categories/food/tearoom.png"},
  "address"=>"819 N Rush St", "crossstreet"=>"Rush & Pearson", "city"=>"Chicago", "state"=>"IL", "zip"=>"60611",
  "lat"=>41.897146, "lng"=>-87.625386, "stats"=>{"herenow"=>"0"}, "distance"=>490},
 # pizza - chicago
 {"id"=>153168, "name"=>"Lou Malnati's Pizzeria",
  "primarycategory"=>{"id"=>79081, "fullpathname"=>"Food:Pizza", "nodename"=>"Pizza", "iconurl"=>"http://foursquare.com/img/categories/food/pizza.png"},
  "address"=>"439 N. Wells St.", "crossstreet"=>"Hubbard St.", "city"=>"Chicago", "state"=>"IL", "zip"=>"60654",
  "lat"=>41.890344, "lng"=>-87.633742, "stats"=>{"herenow"=>"0"}, "distance"=>706},
 {"id"=>45048, "name"=>"Gino's East Pizza",
  "primarycategory"=>{"id"=>79081, "fullpathname"=>"Food:Pizza", "nodename"=>"Pizza", "iconurl"=>"http://foursquare.com/img/categories/food/pizza.png"},
  "address"=>"162 E Superior St", "city"=>"Chicago", "state"=>"IL", "zip"=>"60611", "lat"=>41.8962, "lng"=>-87.6233,
  "stats"=>{"herenow"=>"0"}, "phone"=>"3122663337", "distance"=>656}, 
 {"id"=>135735, "name"=>"Giordano's",
  "primarycategory"=>{"id"=>79081, "fullpathname"=>"Food:Pizza", "nodename"=>"Pizza", "iconurl"=>"http://foursquare.com/img/categories/food/pizza.png"},
  "address"=>"730 N. Rush St.", "crossstreet"=>"at Superior St", "city"=>"Chicago", "state"=>"IL", "zip"=>"60611",
  "lat"=>41.895649, "lng"=>-87.625473, "stats"=>{"herenow"=>"0"}, "phone"=>"3129510747", "distance"=>483},
 # bar
 {"id"=>684215, "name"=>"Streeter's Tavern",
  "primarycategory"=>{"id"=>79158, "fullpathname"=>"Nightlife:Dive Bar", "nodename"=>"Dive Bar", "iconurl"=>"http://foursquare.com/img/categories/nightlife/default.png"},
  "address"=>"50 E. Chicago Ave.", "crossstreet"=>"at Wabash", "city"=>"Chicago", "state"=>"IL", "zip"=>"60611", 
  "lat"=>41.8967385, "lng"=>-87.6263327, "stats"=>{"herenow"=>"0"}, "phone"=>"3129445206", "distance"=>406},
 {"id"=>12531, "name"=>"Hopleaf Bar",
  "primarycategory"=>{"id"=>79153, "fullpathname"=>"Nightlife:Bar", "nodename"=>"Bar", "iconurl"=>"http://foursquare.com/img/categories/nightlife/default.png"},
  "address"=>"5148 N. Clark St", "crossstreet"=>"at Foster Ave", "city"=>"Chicago", "state"=>"IL", "zip"=>"60640",
  "lat"=>41.975814, "lng"=>-87.668739, "stats"=>{"herenow"=>"0"}, "phone"=>"7733349851", "distance"=>9369},
 {"id"=>88928, "name"=>"The Beer Bistro",
  "primarycategory"=>{"id"=>79153, "fullpathname"=>"Nightlife:Bar", "nodename"=>"Bar", "iconurl"=>"http://foursquare.com/img/categories/nightlife/default.png"},
  "address"=>"1061 W. Madison", "city"=>"Chicago", "state"=>"IL", "zip"=>"60607", "lat"=>41.8814, "lng"=>-87.6543,
  "stats"=>{"herenow"=>"0"}, "distance"=>2539},
 # restaurant
 {"id"=>76668, "name"=>"Paramount Room",
   "primarycategory"=>{"id"=>79155, "fullpathname"=>"Nightlife:Brewery / Microbrewery", "nodename"=>"Brewery / Microbrewery", "iconurl"=>"http://foursquare.com/img/categories/nightlife/brewery.png"},
   "address"=>"415 North Milwaukee", "crossstreet"=>"Kinzie and Milwaukee", "city"=>"Chicago", "state"=>"IL", "lat"=>41.889663,
   "lng"=>-87.644823, "stats"=>{"herenow"=>"0"}, "twitter"=>"paramountroom", "distance"=>1354},
 {"id"=>1207640, "name"=>"Dos Diablos",
  "primarycategory"=>{"id"=>79076, "fullpathname"=>"Food:Mexican", "nodename"=>"Mexican", "iconurl"=>"http://foursquare.com/img/categories/food/default.png"},
  "address"=>"15 W Hubbard", "crossstreet"=>"State", "city"=>"Chicago", "state"=>"Illinois", "lat"=>41.8900428,
  "lng"=>-87.6286873, "stats"=>{"herenow"=>"0"}, "distance"=>738},
 {"id"=>131820, "name"=>"Volare",
   "primarycategory"=>{"id"=>79069, "fullpathname"=>"Food:Italian", "nodename"=>"Italian", "iconurl"=>"http://foursquare.com/img/categories/food/default.png"},
   "address"=>"201 E Grand Ave", "city"=>"Chicago", "state"=>"IL", "lat"=>41.891518, "lng"=>-87.622492, 
   "stats"=>{"herenow"=>"0"}, "distance"=>904},
 # coffee - boston
 {"id"=> 109090, "name"=>"Starbucks",
   "primarycategory"=>{"id"=>79049, "fullpathname"=>"Food:Café", "nodename"=>"Café","iconurl"=>"http://foursquare.com/img/categories/food/cafe.png"},
   "address"=>"100 Cambridgeside Pl","city"=>"Cambridge","state"=>"MA","zip"=>"02142","verified"=>true,
   "lat"=>42.367406794909705,"lng"=>-71.07631802558899,
   "stats"=>{"herenow"=>"0"},"phone"=>"6176219507","twitter"=>"Starbucks","distance"=>1661},
 {"id"=>1897522,"name"=>"Pavement Coffeehouse",
   "primarycategory"=>{"id"=>79052,"fullpathname"=>"Food:Coffee Shop","nodename"=>"Coffee Shop",
                       "iconurl"=>"http://foursquare.com/img/categories/food/coffeeshop.png"},
   "address"=>"1096 Boylston St", "crossstreet"=>"btw Hemenway & Mass Ave","city"=>"Boston","state"=>"MA",
   "zip"=>"02115", "verified"=>false,"lat"=>42.34680938399482,"lng"=>-71.08903169631958,
   "stats"=>{"herenow"=>"0"},"phone"=>"6178597080","twitter"=>"Pavementcoffee","distance"=>2690},
 {"id"=>83701,"name"=>"Boston Common Coffee Co.",
   "primarycategory"=>{"id"=>79052,"fullpathname"=>"Food:Coffee Shop","nodename"=>"Coffee Shop",
                      "iconurl"=>"http://foursquare.com/img/categories/food/coffeeshop.png"},
   "address"=>"515 Washington Street","crossstreet"=>"West Street","city"=>"Boston","state"=>"MA","zip"=>"02110",
   "verified"=>false,"lat"=>42.3543,"lng"=>-71.0621,"stats"=>{"herenow"=>"0"},
   "phone"=>"6176959700","distance"=>473},
  # pizza - boston
  {"id"=>212915,"name"=>"Ducali Pizzeria & Bar",
    "primarycategory"=>{"id"=>79081,"fullpathname"=>"Food:Pizza","nodename"=>"Pizza",
                       "iconurl"=>"http://foursquare.com/img/categories/food/pizza.png"},
    "address"=>"289 Causeway St","city"=>"Boston","state"=>"MA","zip"=>"02113","verified"=>false,
    "lat"=>42.367123,"lng"=>-71.058133,"stats"=>{"herenow"=>"0"},"phone"=>"6177424144","twitter"=>"Ducali",
    "distance"=>994},
  {"id"=>66142,"name"=>"New York Pizza",
    "primarycategory"=>{"id"=>79081,"fullpathname"=>"Food:Pizza","nodename"=>"Pizza",
                       "iconurl"=>"http://foursquare.com/img/categories/food/pizza.png"},
    "address"=>"224 Tremont St","crossstreet"=>"btw Stuart & Boylston","city"=>"Boston","state"=>"MA",
    "zip"=>"02116","verified"=>false,"lat"=>42.3514,"lng"=>-71.0646,"stats"=>{"herenow"=>"0"},
    "distance"=>849},
  {"id"=>69904,"name"=>"Santarpio's Pizza",
    "primarycategory"=>{"id"=>79081,"fullpathname"=>"Food:Pizza","nodename"=>"Pizza",
                       "iconurl"=>"http://foursquare.com/img/categories/food/pizza.png"},
    "address"=>"111 Chelsea St.","crossstreet"=>"Chelsea & Porter","city"=>"Boston","state"=>"MA",
    "verified"=>false,"lat"=>42.3726,"lng"=>-71.0353,"stats"=>{"herenow"=>"0"},"distance"=>2596},
].each do |hash|
  LocationImport.import_location(hash['id'].to_s, Source.foursquare, hash)
end
puts "#{Time.now}: imported #{Location.count} locations"

# users
@chicago  = Locality.resolve("Chicago, IL", :create => true)
@boston   = Locality.resolve("Boston, MA", :create => true)
[{"handle" => "chicago_coffee_gal", 'gender' => 'female', "password" => 'coffee', 'password_confirmation' => 'coffee',
  'city' => @chicago, :photos_attributes => [{:source => 'photobucket', :priority => 1, :url => @girl_pics[0]}]},
 {"handle" => "chicago_coffee_guy", 'gender' => 'male', "password" => 'coffee', 'password_confirmation' => 'coffee',
  'city' => @chicago},
 {"handle" => "chicago_pizza_gal", 'gender' => 'female', "password" => 'pizza', 'password_confirmation' => 'pizza',
  'city' => @chicago, :photos_attributes => [{:source => 'photobucket', :priority => 1, :url => @girl_pics[1]}]},
 {"handle" => "chicago_pizza_guy", 'gender' => 'male', "password" => 'pizza', 'password_confirmation' => 'pizza',
  'city' => @chicago},
 {"handle" => "chicago_bar_gal", 'gender' => 'female', "password" => 'bar', 'password_confirmation' => 'bar',
  'city' => @chicago, :photos_attributes => [{:source => 'photobucket', :priority => 1, :url => @girl_pics[2]}]},
 {"handle" => "chicago_bar_guy", 'gender' => 'male', "password" => 'bar', 'password_confirmation' => 'bar',
  'city' => @chicago},
 {"handle" => "chicago_foodie_gal", 'gender' => 'female', "password" => 'foodie', 'password_confirmation' => 'foodie',
  'city' => @chicago, :photos_attributes => [{:source => 'photobucket', :priority => 1, :url => @girl_pics[3]}]},
 {"handle" => "chicago_foodie_guy", 'gender' => 'male', "password" => 'foodie', 'password_confirmation' => 'foodie',
  'city' => @chicago},
 {"handle" => "boston_coffee_gal", 'gender' => 'female', "password" => 'coffee', 'password_confirmation' => 'coffee',
  'city' => @boston, :photos_attributes => [{:source => 'photobucket', :priority => 1, :url => @girl_pics[4]}]},
 {"handle" => "boston_coffee_guy", 'gender' => 'male', "password" => 'coffee', 'password_confirmation' => 'coffee',
  'city' => @boston, :photos_attributes => [{:source => 'photobucket', :priority => 1, :url => @guy_pics[0]}]},
 {"handle" => "boston_pizza_gal", 'gender' => 'female', "password" => 'pizza', 'password_confirmation' => 'pizza',
  'city' => @boston, :photos_attributes => [{:source => 'photobucket', :priority => 1, :url => @girl_pics[4]}]},
 {"handle" => "boston_pizza_guy", 'gender' => 'male', "password" => 'pizza', 'password_confirmation' => 'pizza',
  'city' => @boston},
].each do |hash|
  User.create(hash)
end
puts "#{Time.now}: imported #{User.count} users"

def import_user(hash)
  @user = User.find_by_handle(hash[:user])
  hash[:locations].each do |loc_source_id|
    @location = Location.joins(:location_source).where("location_sources.source_id" => loc_source_id).first
    @user.checkins.create(:location => @location, :checkin_at => Time.zone.now - 3.days,
                          :source_id => @location.location_source.id, :source_type => Source.foursquare)
  end
end

# chicago checkins
puts "#{Time.now}: adding chicago checkins"
[{:user => 'chicago_coffee_gal', :locations => ['108207', '564552', '135721']},
 {:user => 'chicago_coffee_guy', :locations => ['108207', '564552', '135721']},
 {:user => 'chicago_pizza_gal', :locations => ['153168', '45048', '135735']},
 {:user => 'chicago_pizza_guy', :locations => ['153168', '45048', '135735']},
 {:user => 'chicago_bar_gal', :locations => ['684215', '12531', '88928']},
 {:user => 'chicago_bar_guy', :locations => ['684215', '12531', '88928']},
 {:user => 'chicago_foodie_gal', :locations => ['76668', '1207640', '131820']},
 {:user => 'chicago_foodie_guy', :locations => ['76668', '1207640', '131820']},].each do |hash|
   import_user(hash)
end

# boston checkins
puts "#{Time.now}: adding boston checkins"
[{:user => 'boston_coffee_gal', :locations => ['109090', '1897522', '83701']},
 {:user => 'boston_coffee_guy', :locations => ['109090', '1897522', '83701']},
 {:user => 'boston_pizza_gal', :locations => ['212915', '66142', '69904']},
 {:user => 'boston_pizza_guy', :locations => ['212915', '66142', '69904']},
].each do |hash|
  import_user(hash)
end

puts "#{Time.now}: imported #{Checkin.count} checkins"


