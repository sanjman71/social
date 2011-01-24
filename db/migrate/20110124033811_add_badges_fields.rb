class AddBadgesFields < ActiveRecord::Migration
  def self.up
    change_table :badges do |t|
      t.string  :tagline, :length => 100
      t.timestamps
    end
  end

  def self.down
    remove_column :badges, :tagline
    remove_column :badges, :updated_at
    remove_column :badges, :created_at
  end
end
