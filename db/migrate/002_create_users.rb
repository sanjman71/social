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
      t.string    :state,     :limit => 50, :null => :false
      t.integer   :rpx,       :default => 0
      t.integer   :email_addresses_count, :default => 0
      t.integer   :phone_numbers_count, :default => 0
      t.timestamps
    end
    
    add_index :users, :handle
    add_index :users, :state
    add_index :users, :rpx
    add_index :users, :email_addresses_count
    add_index :users, :phone_numbers_count
    add_index :users, :reset_password_token, :unique => true

    create_table :oauths do |t|
      t.references  :user
      t.string      :name,                :limit => 50
      t.string      :access_token,        :limit => 200, :null => :false
      t.string      :access_token_secret, :limit => 200, :null => :false
      t.datetime    :expires_at
      t.string      :refresh_token,       :limit => 200
    end

    add_index :oauths, :user_id
    add_index :oauths, [:user_id, :name]

    create_table :checkins do |t|
      t.references  :user
      t.references  :location
      t.datetime    :checkin_at
      t.integer     :source_id                    # checkin id
      t.string      :source_type, :limit => 50    # checkin source (e.g. 'fs', 'fb')
      t.timestamps
    end
    
    add_index :checkins, :user_id
    add_index :checkins, :location_id
  end

  def self.down
    drop_table :users
    drop_table :oauths
    drop_table :checkins
  end
end
