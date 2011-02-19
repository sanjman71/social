class AddUserPreferences < ActiveRecord::Migration
  def self.up
    change_table :users do |t|
      t.text :preferences
    end
  end

  def self.down
    remove_column :users, :preferences
  end
end
