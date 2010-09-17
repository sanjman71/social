class AddAlerts < ActiveRecord::Migration
  def self.up
    create_table :alerts do |t|
      t.references  :user,        :null => false
      t.integer     :sender_id,   :null => true
      t.string      :level,       :limit => 50, :null => false
      t.string      :subject,     :limit => 50, :null => false
      t.string      :message,     :limit => 200, :null => false
    end
    
    add_index :alerts, :user_id
    add_index :alerts, :sender_id
  end

  def self.down
    drop_table :alerts
  end
end
