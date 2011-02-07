class AddPlannedCheckinReminderAt < ActiveRecord::Migration
  def self.up
    change_table :planned_checkins do |t|
      t.datetime  :reminder_at
    end

    add_index :planned_checkins, :reminder_at
  end

  def self.down
    remove_column :planned_checkins, :reminder_at
  end
end
