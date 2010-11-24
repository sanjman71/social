class AddDeltaIndexes < ActiveRecord::Migration
  def self.up
    add_index :checkins, :delta
    add_index :locations, :delta
    add_index :users, :delta
  end

  def self.down
    remove_index :checkins, :delta
    remove_index :locations, :delta
    remove_index :users, :delta
  end
end
