class CreateTeams < ActiveRecord::Migration[7.2]
  def change
    create_table "teams", force: :cascade do |t|
      t.string "name", null: false
      t.string "short_name"
      t.string "slug", null: false
      t.string "location"
      t.string "emoji"
      t.string "color_primary"
      t.string "color_secondary"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.boolean "color_text_light", default: false
      t.string "sport"
      t.string "league"
      t.string "conference"
      t.string "division"
      t.jsonb "rivals", default: []
      t.string "team_website"
      t.string "coaches_url"
      t.index ["slug"], name: "index_teams_on_slug", unique: true
      t.index ["sport", "league"], name: "index_teams_on_sport_and_league"
    end
  end
end
