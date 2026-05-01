class CreateDepthChartEntries < ActiveRecord::Migration[7.2]
  def change
    create_table "depth_chart_entries", force: :cascade do |t|
      t.string "depth_chart_slug", null: false
      t.string "person_slug", null: false
      t.string "position", null: false
      t.string "side", null: false
      t.integer "depth", null: false
      t.boolean "locked", default: false, null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.string "formation_slot"
      t.index ["depth_chart_slug", "person_slug", "position"], name: "idx_dce_unique", unique: true
      t.index ["depth_chart_slug", "position", "depth"], name: "idx_on_depth_chart_slug_position_depth_8e80d39ff6"
      t.index ["depth_chart_slug"], name: "index_depth_chart_entries_on_depth_chart_slug"
      t.index ["formation_slot"], name: "index_depth_chart_entries_on_formation_slot"
    end
  end
end
