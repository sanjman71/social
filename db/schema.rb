# This file is auto-generated from the current state of the database. Instead 
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your 
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 2) do

  create_table "chains", :force => true do |t|
    t.string  "name"
    t.integer "places_count", :default => 0
  end

  add_index "chains", ["name"], :name => "index_chains_on_name"
  add_index "chains", ["places_count"], :name => "index_chains_on_places_count"

  create_table "checkins", :force => true do |t|
    t.integer  "user_id"
    t.integer  "location_id"
    t.datetime "checkin_at"
    t.integer  "source_id"
    t.string   "source_type", :limit => 50
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "checkins", ["location_id"], :name => "index_checkins_on_location_id"
  add_index "checkins", ["user_id"], :name => "index_checkins_on_user_id"

  create_table "cities", :force => true do |t|
    t.string  "name",                :limit => 30
    t.integer "state_id"
    t.decimal "lat",                               :precision => 15, :scale => 10
    t.decimal "lng",                               :precision => 15, :scale => 10
    t.integer "timezone_id"
    t.integer "neighborhoods_count",                                               :default => 0
    t.integer "locations_count",                                                   :default => 0
  end

  add_index "cities", ["locations_count"], :name => "index_cities_on_locations_count"
  add_index "cities", ["state_id", "locations_count"], :name => "index_cities_on_state_and_locations"
  add_index "cities", ["state_id", "name"], :name => "index_cities_on_state_and_name"
  add_index "cities", ["state_id"], :name => "index_cities_on_state_id"
  add_index "cities", ["timezone_id"], :name => "index_cities_on_timezone_id"

  create_table "countries", :force => true do |t|
    t.string  "name",            :limit => 30
    t.string  "code",            :limit => 2
    t.integer "locations_count",               :default => 0
  end

  add_index "countries", ["code"], :name => "index_countries_on_code"
  add_index "countries", ["locations_count"], :name => "index_countries_on_locations_count"

  create_table "email_addresses", :force => true do |t|
    t.integer  "emailable_id"
    t.string   "emailable_type",        :limit => 50
    t.string   "identifier",            :limit => 200
    t.string   "address",               :limit => 100
    t.integer  "priority",                             :default => 1
    t.string   "state",                 :limit => 50
    t.string   "verification_code",     :limit => 50
    t.datetime "verification_sent_at"
    t.datetime "verified_at"
    t.integer  "verification_failures",                :default => 0
  end

  add_index "email_addresses", ["address"], :name => "index_email_addresses_on_address"
  add_index "email_addresses", ["emailable_id", "emailable_type", "priority"], :name => "index_email_on_emailable_and_priority"
  add_index "email_addresses", ["emailable_id", "emailable_type"], :name => "index_email_addresses_on_emailable_id_and_emailable_type"
  add_index "email_addresses", ["emailable_type"], :name => "index_email_addresses_on_emailable_type"

  create_table "location_neighborhoods", :force => true do |t|
    t.integer "location_id"
    t.integer "neighborhood_id"
  end

  add_index "location_neighborhoods", ["location_id"], :name => "index_ln_on_locations"
  add_index "location_neighborhoods", ["neighborhood_id"], :name => "index_ln_on_neighborhoods"

  create_table "location_places", :force => true do |t|
    t.integer "location_id"
    t.integer "place_id"
  end

  add_index "location_places", ["location_id"], :name => "index_location_places_on_location_id"
  add_index "location_places", ["place_id"], :name => "index_location_places_on_place_id"

  create_table "location_sources", :force => true do |t|
    t.integer  "location_id"
    t.integer  "source_id"
    t.string   "source_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "location_sources", ["location_id"], :name => "index_location_sources_on_location_id"
  add_index "location_sources", ["source_id", "source_type"], :name => "index_location_sources_on_source_id_and_source_type"

  create_table "locations", :force => true do |t|
    t.string   "name",                  :limit => 30
    t.string   "street_address"
    t.integer  "city_id"
    t.integer  "state_id"
    t.integer  "zip_id"
    t.integer  "country_id"
    t.integer  "timezone_id"
    t.integer  "neighborhoods_count",                                                 :default => 0
    t.integer  "phone_numbers_count",                                                 :default => 0
    t.integer  "email_addresses_count",                                               :default => 0
    t.decimal  "lat",                                 :precision => 15, :scale => 10
    t.decimal  "lng",                                 :precision => 15, :scale => 10
    t.integer  "popularity",                                                          :default => 0
    t.integer  "recommendations_count",                                               :default => 0
    t.integer  "events_count",                                                        :default => 0
    t.integer  "status",                                                              :default => 0
    t.integer  "refer_to",                                                            :default => 0
    t.boolean  "delta"
    t.datetime "urban_mapping_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "locations", ["city_id", "street_address"], :name => "index_locations_on_city_id_and_street_address"
  add_index "locations", ["city_id"], :name => "index_locations_on_city"
  add_index "locations", ["email_addresses_count"], :name => "index_locations_on_email_addresses_count"
  add_index "locations", ["events_count"], :name => "index_locations_on_events_count"
  add_index "locations", ["neighborhoods_count"], :name => "index_locations_on_neighborhoods_count"
  add_index "locations", ["phone_numbers_count"], :name => "index_locations_on_phone_numbers_count"
  add_index "locations", ["popularity"], :name => "index_locations_on_popularity"
  add_index "locations", ["recommendations_count"], :name => "index_locations_on_recommendations_count"
  add_index "locations", ["status"], :name => "index_locations_on_status"
  add_index "locations", ["timezone_id"], :name => "index_locations_on_timezone_id"
  add_index "locations", ["updated_at"], :name => "index_locations_on_updated_at"

  create_table "neighborhoods", :force => true do |t|
    t.string  "name",            :limit => 50
    t.integer "city_id"
    t.decimal "lat",                           :precision => 15, :scale => 10
    t.decimal "lng",                           :precision => 15, :scale => 10
    t.integer "locations_count",                                               :default => 0
  end

  add_index "neighborhoods", ["city_id", "locations_count"], :name => "index_hoods_on_city_and_locations"
  add_index "neighborhoods", ["city_id"], :name => "index_hoods_on_city"
  add_index "neighborhoods", ["locations_count"], :name => "index_hoods_on_locations"

  create_table "oauths", :force => true do |t|
    t.integer  "user_id"
    t.string   "name",                :limit => 50
    t.string   "access_token",        :limit => 200
    t.string   "access_token_secret", :limit => 200
    t.datetime "expires_at"
    t.string   "refresh_token",       :limit => 200
  end

  add_index "oauths", ["user_id", "name"], :name => "index_oauths_on_user_id_and_name"
  add_index "oauths", ["user_id"], :name => "index_oauths_on_user_id"

  create_table "phone_numbers", :force => true do |t|
    t.string  "name",          :limit => 20
    t.string  "address",       :limit => 20
    t.integer "callable_id"
    t.string  "callable_type", :limit => 20
    t.integer "priority",                    :default => 1
    t.string  "state",         :limit => 50
  end

  add_index "phone_numbers", ["address"], :name => "index_phone_numbers_on_address"
  add_index "phone_numbers", ["callable_id", "callable_type"], :name => "index_phone_numbers_on_callable"

  create_table "places", :force => true do |t|
    t.string  "name",                :limit => 50
    t.integer "locations_count",                   :default => 0
    t.integer "phone_numbers_count",               :default => 0
    t.integer "timezone_id"
    t.integer "chain_id"
    t.integer "taggings_count",                    :default => 0
    t.integer "tag_groups_count",                  :default => 0
  end

  add_index "places", ["name"], :name => "index_places_on_name"
  add_index "places", ["tag_groups_count"], :name => "index_places_on_tag_groups_count"
  add_index "places", ["taggings_count"], :name => "index_places_on_taggings_count"
  add_index "places", ["timezone_id"], :name => "index_places_on_timezone_id"

  create_table "states", :force => true do |t|
    t.string  "name",            :limit => 30
    t.string  "code",            :limit => 2
    t.integer "country_id"
    t.decimal "lat",                           :precision => 15, :scale => 10
    t.decimal "lng",                           :precision => 15, :scale => 10
    t.integer "timezone_id"
    t.integer "cities_count",                                                  :default => 0
    t.integer "zips_count",                                                    :default => 0
    t.integer "locations_count",                                               :default => 0
    t.integer "events",                                                        :default => 0
  end

  add_index "states", ["country_id", "code"], :name => "index_states_on_country_id_and_code"
  add_index "states", ["country_id", "locations_count"], :name => "index_states_on_country_id_and_locations_count"
  add_index "states", ["country_id"], :name => "index_states_on_country_id"
  add_index "states", ["timezone_id"], :name => "index_states_on_timezone_id"

  create_table "timezones", :force => true do |t|
    t.string  "name",                 :limit => 100, :null => false
    t.integer "utc_offset",                          :null => false
    t.integer "utc_dst_offset",                      :null => false
    t.string  "rails_time_zone_name", :limit => 100
  end

  create_table "users", :force => true do |t|
    t.string   "name",                  :limit => 100, :default => ""
    t.string   "handle",                :limit => 100
    t.string   "email",                                :default => "", :null => false
    t.string   "encrypted_password",    :limit => 128, :default => "", :null => false
    t.string   "password_salt",                        :default => "", :null => false
    t.string   "reset_password_token"
    t.string   "remember_token"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                        :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "state",                 :limit => 50
    t.integer  "rpx",                                  :default => 0
    t.integer  "email_addresses_count",                :default => 0
    t.integer  "phone_numbers_count",                  :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["email_addresses_count"], :name => "index_users_on_email_addresses_count"
  add_index "users", ["handle"], :name => "index_users_on_handle"
  add_index "users", ["phone_numbers_count"], :name => "index_users_on_phone_numbers_count"
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true
  add_index "users", ["rpx"], :name => "index_users_on_rpx"
  add_index "users", ["state"], :name => "index_users_on_state"

  create_table "zips", :force => true do |t|
    t.string  "name",            :limit => 10
    t.integer "state_id"
    t.decimal "lat",                           :precision => 15, :scale => 10
    t.decimal "lng",                           :precision => 15, :scale => 10
    t.integer "timezone_id"
    t.integer "locations_count",                                               :default => 0
  end

  add_index "zips", ["state_id", "locations_count"], :name => "index_zips_on_state_id_and_locations_count"
  add_index "zips", ["state_id"], :name => "index_zips_on_state_id"
  add_index "zips", ["timezone_id"], :name => "index_zips_on_timezone_id"

end
