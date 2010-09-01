class AddSuggestions < ActiveRecord::Migration
  def self.up
    create_table :suggestions do |t|
      # t.integer     :user1_suggestion_id, :null => false
      # t.integer     :user2_suggestion_id, :null => false
      t.string      :user1_action, :limit => 50
      t.string      :user2_action, :limit => 50
      t.string      :state, :limit => 50, :null => false
      t.references  :location
      t.string      :when, :limit => 50  # e.g. this week, next week, today
    end
    
    create_table :user_suggestions do |t|
      t.references  :user
      t.references  :suggestion
      t.string      :state, :limit => 50, :null => false
    end
  end

  def self.down
    drop_table :suggestions
    drop_table :user_suggestions
  end
end
