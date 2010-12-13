class AddUserMember < ActiveRecord::Migration
  def self.up
    change_table :users do |t|
      t.boolean :member, :default => false
    end

    add_index :users, :member
  end

  def self.down
    remove_column :users, :member
  end
end
