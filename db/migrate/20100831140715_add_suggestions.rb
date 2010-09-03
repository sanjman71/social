class AddSuggestions < ActiveRecord::Migration
  def self.up
    create_table :suggestions do |t|
      t.references  :location
      t.string      :state,   :limit => 50, :null => false
      t.string      :when,    :limit => 50  # e.g. this week, next week, today
    end
    
    create_table :user_suggestions do |t|
      t.references  :user
      t.references  :suggestion
      t.string      :state,     :limit => 50, :null => false
      t.string      :message,   :limit => 200
      t.boolean     :dirty,     :default => false
    end
  end

  def self.down
    drop_table :suggestions
    drop_table :user_suggestions
  end
end
