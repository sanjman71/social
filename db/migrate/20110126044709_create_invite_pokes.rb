class CreateInvitePokes < ActiveRecord::Migration
  def self.up
    create_table :invite_pokes do |t|
      t.integer       :invitee_id   # invited user
      t.integer       :friend_id    # friend of user invited
      t.integer       :poker_id     # user who wants to invite user
      t.timestamps
    end
  end

  def self.down
    drop_table :invite_pokes
  end
end
