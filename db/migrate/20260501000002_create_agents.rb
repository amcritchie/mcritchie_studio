class CreateAgents < ActiveRecord::Migration[7.2]
  def change
    create_table "agents", force: :cascade do |t|
      t.string "name", null: false
      t.string "slug", null: false
      t.string "status", default: "active"
      t.text "description"
      t.string "agent_type"
      t.string "title"
      t.jsonb "config", default: {}
      t.jsonb "metadata", default: {}
      t.datetime "last_active_at"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.string "avatar"
      t.integer "position", default: 0
      t.index ["slug"], name: "index_agents_on_slug", unique: true
      t.index ["status"], name: "index_agents_on_status"
    end
  end
end
