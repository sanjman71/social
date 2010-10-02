class AddTagBadges < ActiveRecord::Migration
  def self.up
    create_table :tag_badges do |t|
      t.string  :regex, :limit => 200, :null => false
      t.string  :name,  :limit => 50, :null => false
    end

    add_index :tag_badges, :name

    create_table :tag_badgings do |t|
      t.references  :user, :null => false
      t.references  :tag_badge, :null => false
    end

    add_index :tag_badgings, :user_id
    add_index :tag_badgings, :tag_badge_id
  end

  def self.down
    drop_table :tag_badges
    drop_table :tag_badgings
  end
end
