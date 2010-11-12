class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string    :name,      :limit => 100, :default => '', :null => true
      t.string    :handle,    :limit => 100
      t.database_authenticatable :null => false
      # t.confirmable
      t.recoverable
      t.rememberable
      t.trackable
      # t.lockable :lock_strategy => :failed_attempts, :unlock_strategy => :both
      t.string    :state,                 :limit => 50, :null => :false
      t.integer   :points,                :default => 0
      t.integer   :gender,                :default => 0 # e.g. 'female', 'male'
      t.integer   :orientation,           :default => 3 # e.g. 'bisexual', 'gay', 'straight'
      t.string    :facebook_id,           :limit => 50
      t.string    :foursquare_id,         :limit => 50
      t.string    :twitter_id,            :limit => 50
      t.string    :twitter_screen_name,   :limit => 50
      t.integer   :checkins_count,        :default => 0 # counter cache
      t.integer   :city_id
      t.decimal   :lat,                   :precision => 15, :scale => 10
      t.decimal   :lng,                   :precision => 15, :scale => 10
      t.integer   :rpx,                   :default => 0
      t.boolean   :delta,                 :default => 0
      t.integer   :email_addresses_count, :default => 0 # counter cache
      t.integer   :phone_numbers_count,   :default => 0 # counter cache
      t.integer   :radius,                :default => 0
      t.integer   :user_density,          :default => 0
      t.integer   :suggestion_density,    :default => 0
      t.timestamps
    end

    add_index :users, :handle
    add_index :users, :state
    add_index :users, :gender
    add_index :users, :facebook_id
    add_index :users, :foursquare_id
    add_index :users, :rpx
    add_index :users, :email_addresses_count
    add_index :users, :phone_numbers_count
    add_index :users, :reset_password_token, :unique => true

    create_table :oauths do |t|
      t.references  :user
      t.string      :provider,            :limit => 50
      t.string      :access_token,        :limit => 200, :null => :false
      t.string      :access_token_secret, :limit => 200, :null => :false
      t.datetime    :expires_at
      t.string      :refresh_token,       :limit => 200
      t.timestamps
    end

    add_index :oauths, :user_id
    add_index :oauths, [:user_id, :provider]

    create_table :checkins do |t|
      t.references  :user
      t.references  :location
      t.datetime    :checkin_at
      t.string      :source_id                    # checkin id
      t.string      :source_type, :limit => 50    # checkin source (e.g. 'facebook', 'foursquare')
      t.timestamps
    end

    add_index :checkins, :user_id
    add_index :checkins, :location_id

    create_table :checkin_logs do |t|
      t.references  :user
      t.string      :source,  :limit => 50   # e.g. 'facebook', 'foursquare'
      t.string      :state,   :limti => 50
      t.integer     :checkins
      t.datetime    :last_check_at
      t.timestamp
    end

    add_index :checkin_logs, :user_id
    add_index :checkin_logs, :source

    create_table :photos do |t|
      t.references  :user
      t.string      :source,    :limit => 50   # e.g. 'facebook', 'foursquare'
      t.string      :url,       :limit => 100
      t.integer     :priority,  :default => 10
      t.timestamp
    end

    add_index :photos, :user_id
    add_index :photos, :source
    add_index :photos, :priority
  end

  def self.down
    drop_table :users
    drop_table :oauths
    drop_table :checkins
    drop_table :checkin_logs
  end
end
