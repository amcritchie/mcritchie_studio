class CreateGames < ActiveRecord::Migration[7.2]
  def change
    create_table "games", force: :cascade do |t|
      t.string "slug", null: false
      t.string "slate_slug", null: false
      t.string "home_team_slug", null: false
      t.string "away_team_slug", null: false
      t.datetime "kickoff_at"
      t.string "venue"
      t.string "status", default: "scheduled"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["away_team_slug"], name: "index_games_on_away_team_slug"
      t.index ["home_team_slug"], name: "index_games_on_home_team_slug"
      t.index ["slate_slug"], name: "index_games_on_slate_slug"
      t.index ["slug"], name: "index_games_on_slug", unique: true
    end
  end
end
