class AddUserBirthdate < ActiveRecord::Migration
  def self.up
    change_table :users do |t|
      t.date    :birthdate
      t.integer :age, :default => 0 # calculated from birthdate
      t.index   :age
    end
  end

  def self.down
    remove_column :users, :birthdate
    remove_column :users, :age
  end
end
