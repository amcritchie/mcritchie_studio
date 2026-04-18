class CreateActivities < ActiveRecord::Migration[7.2]
  def change
    create_table :activities do |t|
      t.string :agent_slug
      t.string :activity_type
      t.text :description
      t.string :task_slug
      t.jsonb :metadata, default: {}
      t.string :slug

      t.timestamps
    end

    add_index :activities, :agent_slug
    add_index :activities, :task_slug
    add_index :activities, :activity_type
    add_index :activities, :slug, unique: true
    add_index :activities, [:activity_type, :created_at], name: "index_activities_on_activity_type_and_created_at"
  end
end
