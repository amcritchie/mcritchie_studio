class CreateCoachRankings < ActiveRecord::Migration[7.2]
  def change
    create_table "coach_rankings", force: :cascade do |t|
      t.string "coach_slug", null: false
      t.string "season_slug", null: false
      t.string "rank_type", null: false
      t.integer "rank", null: false
      t.string "tier"
      t.string "slug", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["coach_slug", "rank_type", "season_slug"], name: "index_coach_rankings_unique_type_season", unique: true
      t.index ["coach_slug"], name: "index_coach_rankings_on_coach_slug"
      t.index ["season_slug"], name: "index_coach_rankings_on_season_slug"
      t.index ["slug"], name: "index_coach_rankings_on_slug", unique: true
    end
  end
end
