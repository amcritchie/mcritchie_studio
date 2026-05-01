class CreateTeamRankings < ActiveRecord::Migration[7.2]
  def change
    create_table "team_rankings", force: :cascade do |t|
      t.string "team_slug", null: false
      t.string "season_slug", null: false
      t.string "rank_type", null: false
      t.integer "rank", null: false
      t.decimal "score", precision: 10, scale: 2
      t.integer "week"
      t.string "slug", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["season_slug"], name: "index_team_rankings_on_season_slug"
      t.index ["slug"], name: "index_team_rankings_on_slug", unique: true
      t.index ["team_slug", "rank_type", "season_slug", "week"], name: "idx_team_rankings_unique_with_week", unique: true, where: "(week IS NOT NULL)"
      t.index ["team_slug", "rank_type", "season_slug"], name: "idx_team_rankings_unique_preseason", unique: true, where: "(week IS NULL)"
      t.index ["team_slug"], name: "index_team_rankings_on_team_slug"
    end
  end
end
