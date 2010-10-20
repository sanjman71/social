class AddPlans < ActiveRecord::Migration
  def self.up
    create_table :plans do |t|
      t.references :user, :null => false
      t.references :location, :null => false
    end

    add_index :plans, :user_id
    add_index :plans, :location_id
  end

  def self.down
    drop_table :plans
  end
end
