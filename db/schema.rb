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

ActiveRecord::Schema.define(:version => 20110119032045) do

  create_table "alerts", :force => true do |t|
    t.integer "user_id",                  :null => false
    t.integer "sender_id"
    t.string  "level",     :limit => 50,  :null => false
    t.string  "subject",   :limit => 50,  :null => false
    t.string  "message",   :limit => 200, :null => false
  end

  add_index "alerts", ["sender_id"], :name => "index_alerts_on_sender_id"
  add_index "alerts", ["user_id"], :name => "index_alerts_on_user_id"

  create_table "availabilities", :force => true do |t|
    t.integer  "user_id",                       :null => false
    t.boolean  "now",        :default => false
    t.datetime "start_at"
    t.datetime "end_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "availabilities", ["now"], :name => "index_availabilities_on_now"
  add_index "availabilities", ["user_id"], :name => "index_availabilities_on_user_id"

  create_table "badges", :force => true do |t|
    t.string "regex",   :limit => 200
    t.string "name",    :limit => 50,  :null => false
    t.string "tag_ids"
  end

  add_index "badges", ["name"], :name => "index_badges_on_name"
  add_index "badges", ["tag_ids"], :name => "index_badges_on_tag_ids"

  create_table "badges_privileges", :force => true do |t|
    t.string   "name",         :limit => 50
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "lock_version",               :default => 0, :null => false
  end

  add_index "badges_privileges", ["name"], :name => "index_badges_privileges_on_name"

  create_table "badges_role_privileges", :force => true do |t|
    t.integer  "role_id"
    t.integer  "privilege_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "lock_version", :default => 0, :null => false
  end

  add_index "badges_role_privileges", ["privilege_id", "role_id"], :name => "index_badges_role_privileges_on_privilege_id_and_role_id"
  add_index "badges_role_privileges", ["privilege_id"], :name => "index_badges_role_privileges_on_privilege_id"
  add_index "badges_role_privileges", ["role_id"], :name => "index_badges_role_privileges_on_role_id"

  create_table "badges_roles", :force => true do |t|
    t.string   "name",         :limit => 50
    t.string   "string",       :limit => 50
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "lock_version",               :default => 0, :null => false
  end

  add_index "badges_roles", ["name"], :name => "index_badges_roles_on_name"

  create_table "badges_user_roles", :force => true do |t|
    t.integer  "user_id"
    t.integer  "role_id"
    t.string   "authorizable_type", :limit => 30
    t.integer  "authorizable_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "lock_version",                    :default => 0, :null => false
  end

  add_index "badges_user_roles", ["authorizable_type", "authorizable_id"], :name => "index_on_authorizable"
  add_index "badges_user_roles", ["user_id", "role_id", "authorizable_type", "authorizable_id"], :name => "index_on_user_roles_authorizable"

  create_table "badging_votes", :force => true do |t|
    t.integer  "user_id",    :null => false
    t.integer  "badge_id",   :null => false
    t.integer  "voter_id",   :null => false
    t.integer  "vote",       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "badging_votes", ["user_id", "badge_id"], :name => "index_badging_votes_on_user_id_and_badge_id"
  add_index "badging_votes", ["user_id", "voter_id"], :name => "index_badging_votes_on_user_id_and_voter_id"
  add_index "badging_votes", ["user_id"], :name => "index_badging_votes_on_user_id"

  create_table "badgings", :force => true do |t|
    t.integer "user_id",  :null => false
    t.integer "badge_id", :null => false
  end

  add_index "badgings", ["badge_id"], :name => "index_badgings_on_badge_id"
  add_index "badgings", ["user_id"], :name => "index_badgings_on_user_id"

  create_table "chains", :force => true do |t|
    t.string  "name"
    t.integer "places_count", :default => 0
  end

  add_index "chains", ["name"], :name => "index_chains_on_name"
  add_index "chains", ["places_count"], :name => "index_chains_on_places_count"

  create_table "checkin_logs", :force => true do |t|
    t.integer  "user_id"
    t.string   "source",        :limit => 50
    t.string   "state"
    t.integer  "checkins"
    t.datetime "last_check_at"
  end

  add_index "checkin_logs", ["source"], :name => "index_checkin_logs_on_source"
  add_index "checkin_logs", ["user_id"], :name => "index_checkin_logs_on_user_id"

  create_table "checkins", :force => true do |t|
    t.integer  "user_id"
    t.integer  "location_id"
    t.datetime "checkin_at"
    t.string   "source_id"
    t.string   "source_type", :limit => 50
    t.boolean  "delta",                     :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "checkins", ["delta"], :name => "index_checkins_on_delta"
  add_index "checkins", ["location_id"], :name => "index_checkins_on_location_id"
  add_index "checkins", ["user_id"], :name => "index_checkins_on_user_id"

  create_table "cities", :force => true do |t|
    t.string  "name",                :limit => 30
    t.integer "state_id"
    t.integer "country_id"
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

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

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

  create_table "friendships", :force => true do |t|
    t.integer  "user_id",    :null => false
    t.integer  "friend_id",  :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "friendships", ["friend_id"], :name => "index_friendships_on_friend_id"
  add_index "friendships", ["user_id", "friend_id"], :name => "index_friendships_on_user_id_and_friend_id"
  add_index "friendships", ["user_id"], :name => "index_friendships_on_user_id"

  create_table "invitations", :force => true do |t|
    t.integer  "sender_id",                      :null => false
    t.string   "recipient_email"
    t.string   "token",           :limit => 20,  :null => false
    t.string   "subject",         :limit => 200
    t.text     "body"
    t.datetime "sent_at"
    t.datetime "expires_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "invitations", ["token"], :name => "index_invitations_on_token"

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
    t.string   "source_id"
    t.string   "source_type", :limit => 50
    t.string   "state",       :limit => 50
    t.integer  "tag_count"
    t.datetime "tagged_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "location_sources", ["location_id"], :name => "index_location_sources_on_location_id"
  add_index "location_sources", ["source_id", "source_type"], :name => "index_location_sources_on_source_id_and_source_type"
  add_index "location_sources", ["state"], :name => "index_location_sources_on_state"
  add_index "location_sources", ["tagged_at"], :name => "index_location_sources_on_tagged_at"

  create_table "locations", :force => true do |t|
    t.string   "name",                  :limit => 100
    t.string   "street_address",        :limit => 100
    t.integer  "city_id"
    t.integer  "state_id"
    t.integer  "zipcode_id"
    t.integer  "country_id"
    t.integer  "timezone_id"
    t.integer  "checkins_count",                                                       :default => 0
    t.integer  "neighborhoods_count",                                                  :default => 0
    t.integer  "phone_numbers_count",                                                  :default => 0
    t.integer  "email_addresses_count",                                                :default => 0
    t.decimal  "lat",                                  :precision => 15, :scale => 10
    t.decimal  "lng",                                  :precision => 15, :scale => 10
    t.integer  "popularity",                                                           :default => 0
    t.integer  "status",                                                               :default => 0
    t.integer  "refer_to",                                                             :default => 0
    t.boolean  "delta"
    t.datetime "urban_mapping_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "locations", ["city_id", "street_address"], :name => "index_locations_on_city_id_and_street_address"
  add_index "locations", ["city_id"], :name => "index_locations_on_city"
  add_index "locations", ["delta"], :name => "index_locations_on_delta"
  add_index "locations", ["email_addresses_count"], :name => "index_locations_on_email_addresses_count"
  add_index "locations", ["neighborhoods_count"], :name => "index_locations_on_neighborhoods_count"
  add_index "locations", ["phone_numbers_count"], :name => "index_locations_on_phone_numbers_count"
  add_index "locations", ["popularity"], :name => "index_locations_on_popularity"
  add_index "locations", ["status"], :name => "index_locations_on_status"
  add_index "locations", ["timezone_id"], :name => "index_locations_on_timezone_id"
  add_index "locations", ["updated_at"], :name => "index_locations_on_updated_at"

  create_table "locationships", :force => true do |t|
    t.integer  "location_id",                    :null => false
    t.integer  "user_id",                        :null => false
    t.integer  "my_checkins",     :default => 0
    t.integer  "friend_checkins", :default => 0
    t.integer  "todo_checkins",   :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "locationships", ["location_id"], :name => "index_locationships_on_location_id"
  add_index "locationships", ["user_id", "friend_checkins"], :name => "index_locationships_on_user_id_and_friend_checkins"
  add_index "locationships", ["user_id", "my_checkins"], :name => "index_locationships_on_user_id_and_my_checkins"
  add_index "locationships", ["user_id", "todo_checkins"], :name => "index_locationships_on_user_id_and_todo_checkins"
  add_index "locationships", ["user_id"], :name => "index_locationships_on_user_id"

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
    t.string   "provider",            :limit => 50
    t.string   "access_token",        :limit => 200
    t.string   "access_token_secret", :limit => 200
    t.datetime "expires_at"
    t.string   "refresh_token",       :limit => 200
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "oauths", ["user_id", "provider"], :name => "index_oauths_on_user_id_and_provider"
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

  create_table "photos", :force => true do |t|
    t.integer "user_id"
    t.string  "source",   :limit => 50
    t.string  "url",      :limit => 100
    t.integer "priority",                :default => 10
  end

  add_index "photos", ["priority"], :name => "index_photos_on_priority"
  add_index "photos", ["source"], :name => "index_photos_on_source"
  add_index "photos", ["user_id"], :name => "index_photos_on_user_id"

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

  create_table "planned_checkins", :force => true do |t|
    t.integer  "location_id",                     :null => false
    t.integer  "user_id",                         :null => false
    t.datetime "planned_at"
    t.datetime "expires_at"
    t.datetime "completed_at"
    t.integer  "active",       :default => 0
    t.boolean  "delta",        :default => false
    t.datetime "going_at"
  end

  add_index "planned_checkins", ["expires_at"], :name => "index_planned_checkins_on_expires_at"
  add_index "planned_checkins", ["location_id", "active"], :name => "index_planned_checkins_on_location_id_and_active"
  add_index "planned_checkins", ["location_id"], :name => "index_planned_checkins_on_location_id"
  add_index "planned_checkins", ["user_id", "active"], :name => "index_planned_checkins_on_user_id_and_active"
  add_index "planned_checkins", ["user_id"], :name => "index_planned_checkins_on_user_id"

  create_table "shouts", :force => true do |t|
    t.integer  "user_id"
    t.integer  "location_id"
    t.string   "text"
    t.datetime "expires_at"
    t.boolean  "delta",       :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "shouts", ["location_id"], :name => "index_shouts_on_location_id"
  add_index "shouts", ["user_id"], :name => "index_shouts_on_user_id"

  create_table "states", :force => true do |t|
    t.string  "name",            :limit => 30
    t.string  "code",            :limit => 2
    t.integer "country_id"
    t.decimal "lat",                           :precision => 15, :scale => 10
    t.decimal "lng",                           :precision => 15, :scale => 10
    t.integer "timezone_id"
    t.integer "cities_count",                                                  :default => 0
    t.integer "zipcodes_count",                                                :default => 0
    t.integer "locations_count",                                               :default => 0
    t.integer "events",                                                        :default => 0
  end

  add_index "states", ["country_id", "code"], :name => "index_states_on_country_id_and_code"
  add_index "states", ["country_id", "locations_count"], :name => "index_states_on_country_id_and_locations_count"
  add_index "states", ["country_id"], :name => "index_states_on_country_id"
  add_index "states", ["timezone_id"], :name => "index_states_on_timezone_id"

  create_table "suggestions", :force => true do |t|
    t.integer  "location_id"
    t.string   "state",        :limit => 50, :null => false
    t.string   "when",         :limit => 50
    t.datetime "scheduled_at"
    t.integer  "creator_id"
    t.string   "match",        :limit => 50
  end

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type", :limit => 50
    t.integer  "tagger_id"
    t.string   "tagger_type",   :limit => 50
    t.string   "context",       :limit => 50
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
  add_index "taggings", ["taggable_id", "taggable_type", "context"], :name => "index_taggings_on_taggable_id_and_taggable_type_and_context"

  create_table "tags", :force => true do |t|
    t.string "name", :limit => 50
  end

  create_table "timezones", :force => true do |t|
    t.string  "name",                 :limit => 100, :null => false
    t.integer "utc_offset",                          :null => false
    t.integer "utc_dst_offset",                      :null => false
    t.string  "rails_time_zone_name", :limit => 100
  end

  create_table "user_suggestions", :force => true do |t|
    t.integer "user_id"
    t.integer "suggestion_id"
    t.string  "state",         :limit => 50,                    :null => false
    t.string  "event",         :limit => 50
    t.boolean "alert",                       :default => false
  end

  create_table "users", :force => true do |t|
    t.string   "name",                  :limit => 100,                                 :default => ""
    t.string   "handle",                :limit => 100
    t.string   "email",                                                                :default => "",    :null => false
    t.string   "encrypted_password",    :limit => 128,                                 :default => "",    :null => false
    t.string   "password_salt",                                                        :default => "",    :null => false
    t.string   "reset_password_token"
    t.string   "remember_token"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                                                        :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "state",                 :limit => 50
    t.integer  "points",                                                               :default => 0
    t.integer  "gender",                                                               :default => 0
    t.integer  "orientation",                                                          :default => 3
    t.string   "facebook_id",           :limit => 50
    t.string   "foursquare_id",         :limit => 50
    t.string   "twitter_id",            :limit => 50
    t.string   "twitter_screen_name",   :limit => 50
    t.integer  "checkins_count",                                                       :default => 0
    t.integer  "city_id"
    t.decimal  "lat",                                  :precision => 15, :scale => 10
    t.decimal  "lng",                                  :precision => 15, :scale => 10
    t.integer  "rpx",                                                                  :default => 0
    t.boolean  "delta",                                                                :default => false
    t.integer  "email_addresses_count",                                                :default => 0
    t.integer  "phone_numbers_count",                                                  :default => 0
    t.integer  "radius",                                                               :default => 0
    t.integer  "user_density",                                                         :default => 0
    t.integer  "suggestion_density",                                                   :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "tag_ids"
    t.boolean  "member",                                                               :default => false
    t.string   "invitation_token",      :limit => 20
    t.date     "birthdate"
    t.integer  "age",                                                                  :default => 0
  end

  add_index "users", ["age"], :name => "index_users_on_age"
  add_index "users", ["delta"], :name => "index_users_on_delta"
  add_index "users", ["email_addresses_count"], :name => "index_users_on_email_addresses_count"
  add_index "users", ["facebook_id"], :name => "index_users_on_facebook_id"
  add_index "users", ["foursquare_id"], :name => "index_users_on_foursquare_id"
  add_index "users", ["gender"], :name => "index_users_on_gender"
  add_index "users", ["handle"], :name => "index_users_on_handle"
  add_index "users", ["invitation_token"], :name => "index_users_on_invitation_token"
  add_index "users", ["member"], :name => "index_users_on_member"
  add_index "users", ["phone_numbers_count"], :name => "index_users_on_phone_numbers_count"
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true
  add_index "users", ["rpx"], :name => "index_users_on_rpx"
  add_index "users", ["state"], :name => "index_users_on_state"

  create_table "zipcodes", :force => true do |t|
    t.string  "name",            :limit => 10
    t.integer "state_id"
    t.integer "country_id"
    t.decimal "lat",                           :precision => 15, :scale => 10
    t.decimal "lng",                           :precision => 15, :scale => 10
    t.integer "timezone_id"
    t.integer "locations_count",                                               :default => 0
  end

  add_index "zipcodes", ["state_id", "locations_count"], :name => "index_zips_on_state_id_and_locations_count"
  add_index "zipcodes", ["state_id"], :name => "index_zips_on_state_id"
  add_index "zipcodes", ["timezone_id"], :name => "index_zips_on_timezone_id"

end
