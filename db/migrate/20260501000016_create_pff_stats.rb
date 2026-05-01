class CreatePffStats < ActiveRecord::Migration[7.2]
  def change
    create_table "pff_stats", force: :cascade do |t|
      t.string "athlete_slug", null: false
      t.string "season_slug", null: false
      t.string "stat_type", null: false
      t.string "team_slug"
      t.integer "pff_player_id"
      t.integer "games_played"
      t.jsonb "data", default: {}, null: false
      t.string "slug", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["athlete_slug", "season_slug", "stat_type"], name: "idx_pff_stats_unique", unique: true
      t.index ["data"], name: "index_pff_stats_on_data", using: :gin
      t.index ["pff_player_id"], name: "index_pff_stats_on_pff_player_id"
      t.index ["slug"], name: "index_pff_stats_on_slug", unique: true
      t.index ["stat_type"], name: "index_pff_stats_on_stat_type"
    end
  end
end
