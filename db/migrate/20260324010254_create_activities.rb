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
  end
end
