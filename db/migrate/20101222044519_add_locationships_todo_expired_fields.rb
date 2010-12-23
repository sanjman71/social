class AddLocationshipsTodoExpiredFields < ActiveRecord::Migration
  def self.up
    change_table :locationships do |t|
      t.datetime  :todo_expires_at
      t.datetime  :todo_completed_at
      t.datetime  :todo_expired_at

      t.index     :todo_expires_at
      t.index     :todo_completed_at
      t.index     :todo_expired_at
    end
  end

  def self.down
    remove_column :locationships, :todo_expires_at
    remove_column :locationships, :todo_completed_at
    remove_column :locationships, :todo_expired_at
  end
end
