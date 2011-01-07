class CreatePlannedCheckins < ActiveRecord::Migration
  def self.up
    create_table :planned_checkins do |t|
      t.references  :location, :null => false
      t.references  :user, :null => false
      t.datetime    :planned_at
      t.datetime    :expires_at
      t.datetime    :completed_at
      t.integer     :active, :default => 0
      t.boolean     :delta, :default => 0
    end

    add_index :planned_checkins, :location_id
    add_index :planned_checkins, :user_id
    add_index :planned_checkins, :expires_at
    add_index :planned_checkins, [:user_id, :active]
    add_index :planned_checkins, [:location_id, :active]

    # cleanup locationships table
    remove_column :locationships, :todo_at
    remove_column :locationships, :todo_expires_at
    remove_column :locationships, :todo_completed_at
    remove_column :locationships, :todo_expired_at
  end

  def self.down
    drop_table :planned_checkins
  end
end
