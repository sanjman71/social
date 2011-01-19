class AddBadgesTagIds < ActiveRecord::Migration
  def self.up
    change_table :badges do |t|
      t.string :tag_ids, :length => 150
    end

    add_index :badges, :tag_ids
  end

  def self.down
    remove_column :badges, :tag_ids
  end
end
