class AddBadgingTimestamps < ActiveRecord::Migration
  def self.up
    change_table :badgings do |t|
      t.timestamps
    end
  end

  def self.down
    remove_column :badgings, :updated_at
    remove_column :badgings, :created_at
  end
end
