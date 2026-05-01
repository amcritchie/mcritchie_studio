class CreateUsages < ActiveRecord::Migration[7.2]
  def change
    create_table "usages", force: :cascade do |t|
      t.string "agent_slug"
      t.date "period_date", null: false
      t.string "period_type", null: false
      t.string "model"
      t.integer "tokens_in", default: 0
      t.integer "tokens_out", default: 0
      t.integer "api_calls", default: 0
      t.decimal "cost", precision: 10, scale: 4, default: "0.0"
      t.integer "tasks_completed", default: 0
      t.integer "tasks_failed", default: 0
      t.jsonb "metadata", default: {}
      t.string "slug"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["agent_slug", "period_date", "period_type", "model"], name: "idx_usages_unique", unique: true
      t.index ["agent_slug"], name: "index_usages_on_agent_slug"
      t.index ["slug"], name: "index_usages_on_slug", unique: true
    end
  end
end
