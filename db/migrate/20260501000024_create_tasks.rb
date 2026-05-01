class CreateTasks < ActiveRecord::Migration[7.2]
  def change
    create_table "tasks", force: :cascade do |t|
      t.string "title", null: false
      t.string "slug", null: false
      t.text "description"
      t.string "stage", default: "new"
      t.integer "priority", default: 0
      t.string "agent_slug"
      t.jsonb "required_skills", default: []
      t.jsonb "result", default: {}
      t.jsonb "metadata", default: {}
      t.text "error_message"
      t.integer "position"
      t.datetime "queued_at"
      t.datetime "started_at"
      t.datetime "completed_at"
      t.datetime "failed_at"
      t.datetime "archived_at"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["agent_slug"], name: "index_tasks_on_agent_slug"
      t.index ["priority"], name: "index_tasks_on_priority"
      t.index ["slug"], name: "index_tasks_on_slug", unique: true
      t.index ["stage", "created_at"], name: "index_tasks_on_stage_and_created_at"
      t.index ["stage", "position"], name: "index_tasks_on_stage_and_position"
      t.index ["stage"], name: "index_tasks_on_stage"
    end
  end
end
