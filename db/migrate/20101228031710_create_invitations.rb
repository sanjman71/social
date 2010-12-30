class CreateInvitations < ActiveRecord::Migration
  def self.up
    change_table :users do |t|
      t.string   :invitation_token, :limit => 20
      t.index    :invitation_token # for invitable
    end

    create_table :invitations do |t|
      t.integer       :sender_id, :null => false
      t.string        :recipient_email
      t.string        :token, :limit => 20, :null => false
      t.string        :subject, :limit => 200
      t.text          :body
      t.datetime      :sent_at
      t.datetime      :expires_at
      t.timestamps
    end

    add_index :invitations, :token
  end

  def self.down
    remove_column :users, :invitation_token
    drop_table    :invitation
  end
end
