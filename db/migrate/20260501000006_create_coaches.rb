class CreateCoaches < ActiveRecord::Migration[7.2]
  def change
    create_table "coaches", force: :cascade do |t|
      t.string "person_slug", null: false
      t.string "team_slug", null: false
      t.string "role", null: false
      t.string "lean"
      t.string "sport", null: false
      t.string "slug", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.string "espn_id"
      t.string "espn_headshot_url"
      t.index ["espn_id"], name: "index_coaches_on_espn_id"
      t.index ["person_slug", "team_slug", "role"], name: "index_coaches_unique_role", unique: true
      t.index ["person_slug"], name: "index_coaches_on_person_slug"
      t.index ["slug"], name: "index_coaches_on_slug", unique: true
      t.index ["sport"], name: "index_coaches_on_sport"
      t.index ["team_slug"], name: "index_coaches_on_team_slug"
    end
  end
end
