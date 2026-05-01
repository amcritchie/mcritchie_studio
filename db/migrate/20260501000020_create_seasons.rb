class CreateSeasons < ActiveRecord::Migration[7.2]
  def change
    create_table "seasons", force: :cascade do |t|
      t.integer "year", null: false
      t.string "sport", null: false
      t.string "league", null: false
      t.string "name", null: false
      t.boolean "active", default: false
      t.string "slug", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["league", "active"], name: "index_seasons_on_league_and_active"
      t.index ["slug"], name: "index_seasons_on_slug", unique: true
      t.index ["year", "league"], name: "index_seasons_on_year_and_league", unique: true
    end
  end
end
