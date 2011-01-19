class CreateShouts < ActiveRecord::Migration
  def self.up
    create_table :shouts do |t|
      t.references  :user
      t.references  :location
      t.string      :text,  :length => 200
      t.datetime    :expires_at
      t.boolean     :delta, :default => 0
      t.timestamps
    end
    
    add_index :shouts, :user_id
    add_index :shouts, :location_id
  end

  def self.down
    drop_table :shouts
  end
end
