class CreateLocationships < ActiveRecord::Migration
  def self.up
    create_table :locationships do |t|
      t.references  :location, :null => false
      t.references  :user, :null => false
      t.integer     :checkins, :default => 0
      t.boolean     :plan, :default => 0
      t.integer     :friend_checkins, :default => 0

      t.timestamps
    end

    add_index :locationships, :location_id
    add_index :locationships, :user_id
  end

  def self.down
    drop_table :locationships
  end
end
