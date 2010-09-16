class AddSuggestions < ActiveRecord::Migration
  def self.up
    create_table :suggestions do |t|
      t.references  :location
      t.string      :state,         :limit => 50, :null => false
      t.string      :when,          :limit => 50  # e.g. this week, next week, today
      t.datetime    :scheduled_at
      t.integer     :creator_id
      t.string      :match,         :limit => 50
    end
    
    create_table :user_suggestions do |t|
      t.references  :user
      t.references  :suggestion
      t.string      :state,     :limit => 50, :null => false
      t.string      :event,     :limit => 50
      t.string      :message,   :limit => 200
      t.boolean     :alert,     :default => false
    end
  end

  def self.down
    drop_table :suggestions
    drop_table :user_suggestions
  end
end
