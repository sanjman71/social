class AddPlannedCheckinGoingAt < ActiveRecord::Migration
  def self.up
    change_table :planned_checkins do |t|
      t.datetime  :going_at
    end

    add_index :planned_checkins, :going_at
  end

  def self.down
    remove_column :planned_checkins, :going_at
  end
end
