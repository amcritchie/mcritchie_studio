class CreateTasks < ActiveRecord::Migration[7.2]
  def change
    create_table :tasks do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.text :description
      t.string :stage, default: "new"
      t.integer :priority, default: 0
      t.string :agent_slug
      t.jsonb :required_skills, default: []
      t.jsonb :result, default: {}
      t.jsonb :metadata, default: {}
      t.text :error_message

      t.datetime :queued_at
      t.datetime :started_at
      t.datetime :completed_at
      t.datetime :failed_at
      t.datetime :archived_at

      t.timestamps
    end

    add_index :tasks, :slug, unique: true
    add_index :tasks, :stage
    add_index :tasks, :agent_slug
    add_index :tasks, :priority
  end
end
