class CreateTagBadgingVotes < ActiveRecord::Migration
  def self.up
    create_table :tag_badging_votes do |t|
      t.references  :user, :null => false
      t.references  :tag_badge, :null => false
      t.integer     :voter_id, :null => false
      t.integer     :vote, :null => false

      t.timestamps
    end
    
    add_index :tag_badging_votes, :user_id
    add_index :tag_badging_votes, [:user_id, :tag_badge_id]
    add_index :tag_badging_votes, [:user_id, :voter_id]
  end

  def self.down
    drop_table :tag_badging_votes
  end
end
