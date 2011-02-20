class AddUserFriendSetIds < ActiveRecord::Migration
  def self.up
    change_table :users do |t|
      t.text :friend_set_ids, :default => ''
    end
  end

  def self.down
    remove_column :users, :friend_set_ids
  end
end
