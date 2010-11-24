class ActsAsTaggableOnMigration < ActiveRecord::Migration
  def self.up
    create_table :tags do |t|
      t.string :name, :limit => 50
    end

    create_table :taggings do |t|
      t.references  :tag
      t.integer     :taggable_id
      t.string      :taggable_type, :limit => 50
      t.integer     :tagger_id
      t.string      :tagger_type, :limit => 50
      t.string      :context, :limit => 50

      t.datetime    :created_at
    end

    add_index :taggings, :tag_id
    add_index :taggings, [:taggable_id, :taggable_type, :context]
  end

  def self.down
    drop_table :taggings
    drop_table :tags
  end
end
