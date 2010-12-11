class AddUserTagIds < ActiveRecord::Migration
  def self.up
    change_table :users do |t|
      t.text  :tag_ids
    end
  end

  def self.down
    remove_column :users, :tag_ids
  end
end
