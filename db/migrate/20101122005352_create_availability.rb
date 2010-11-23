class CreateAvailability < ActiveRecord::Migration
  def self.up
    create_table :availabilities do |t|
      t.references  :user, :null => false
      t.boolean     :now, :default => false
      t.datetime    :start_at
      t.datetime    :end_at
      t.timestamps
    end

    add_index :availabilities, :user_id
    add_index :availabilities, :now
  end

  def self.down
    drop_table :availabilities
  end
end
