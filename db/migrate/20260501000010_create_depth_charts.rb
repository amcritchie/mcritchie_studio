class CreateDepthCharts < ActiveRecord::Migration[7.2]
  def change
    create_table "depth_charts", force: :cascade do |t|
      t.string "team_slug", null: false
      t.string "slug", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["slug"], name: "index_depth_charts_on_slug", unique: true
      t.index ["team_slug"], name: "index_depth_charts_on_team_slug", unique: true
    end
  end
end
