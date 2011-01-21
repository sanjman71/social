class AddTagBadges < ActiveRecord::Migration
  def self.up
    create_table :badges do |t|
      t.string  :regex, :limit => 200
      t.string  :name,  :limit => 50, :null => false
    end

    add_index :badges, :name

    create_table :badgings do |t|
      t.references  :user, :null => false
      t.references  :badge, :null => false
    end

    add_index :badgings, :user_id
    add_index :badgings, :badge_id
  end

  def self.down
    drop_table :badges
    drop_table :badgings
  end
end
