class CreateActivities < ActiveRecord::Migration[7.2]
  def change
    create_table "activities", force: :cascade do |t|
      t.string "agent_slug"
      t.string "activity_type"
      t.text "description"
      t.string "task_slug"
      t.jsonb "metadata", default: {}
      t.string "slug"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["activity_type", "created_at"], name: "index_activities_on_activity_type_and_created_at"
      t.index ["activity_type"], name: "index_activities_on_activity_type"
      t.index ["agent_slug"], name: "index_activities_on_agent_slug"
      t.index ["slug"], name: "index_activities_on_slug", unique: true
      t.index ["task_slug"], name: "index_activities_on_task_slug"
    end
  end
end
