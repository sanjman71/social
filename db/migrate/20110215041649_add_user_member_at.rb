class AddUserMemberAt < ActiveRecord::Migration
  def self.up
    change_table :users do |t|
      t.datetime  :member_at
    end

    add_index :users, :member_at
    add_index :users, :name
    add_index :users, :created_at
    add_index :users, :updated_at
  end

  def self.down
    remove_column :users, :member_at
  end
end
