class CreateWalls < ActiveRecord::Migration
  def self.up
    create_table :walls do |t|
      t.references  :checkin
      t.references  :location
      t.text        :member_set_ids, :default => ''
      t.integer     :messages_count # counter cache
      t.timestamps
    end

    add_index :walls, :checkin_id
    add_index :walls, :location_id
    add_index :walls, :messages_count
    add_index :walls, :created_at

    create_table :wall_messages do |t|
      t.references  :wall
      t.string      :message
      t.integer     :sender_id
      t.timestamps
    end

    add_index :wall_messages, :wall_id
    add_index :wall_messages, :sender_id
    add_index :wall_messages, :created_at
  end

  def self.down
    drop_table :walls
    drop_table :wall_messages
  end
end
