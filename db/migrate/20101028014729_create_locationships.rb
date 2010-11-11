class CreateLocationships < ActiveRecord::Migration
  def self.up
    create_table :locationships do |t|
      t.references  :location, :null => false
      t.references  :user, :null => false
      t.integer     :my_checkins, :default => 0
      t.integer     :friend_checkins, :default => 0
      t.integer     :todo_checkins, :default => 0
      t.datetime    :todo_at
      t.timestamps
    end

    add_index :locationships, :location_id
    add_index :locationships, :user_id
    add_index :locationships, [:user_id, :my_checkins]
    add_index :locationships, [:user_id, :friend_checkins]
    add_index :locationships, [:user_id, :todo_checkins]
    add_index :locationships, :todo_at
  end

  def self.down
    drop_table :locationships
  end
end
