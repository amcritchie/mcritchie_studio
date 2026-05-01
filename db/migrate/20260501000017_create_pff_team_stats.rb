class CreatePffTeamStats < ActiveRecord::Migration[7.2]
  def change
    create_table "pff_team_stats", force: :cascade do |t|
      t.string "team_slug", null: false
      t.string "season_slug", null: false
      t.string "stat_type", null: false
      t.jsonb "data", default: {}, null: false
      t.string "slug", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["data"], name: "index_pff_team_stats_on_data", using: :gin
      t.index ["slug"], name: "index_pff_team_stats_on_slug", unique: true
      t.index ["team_slug", "season_slug", "stat_type"], name: "idx_pff_team_stats_unique", unique: true
    end
  end
end
