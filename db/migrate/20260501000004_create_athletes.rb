class CreateAthletes < ActiveRecord::Migration[7.2]
  def change
    create_table "athletes", force: :cascade do |t|
      t.string "person_slug", null: false
      t.string "sport", null: false
      t.string "position"
      t.integer "draft_year"
      t.integer "draft_round"
      t.integer "draft_pick"
      t.string "slug", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.integer "pff_id"
      t.string "skin_tone"
      t.string "hair_description"
      t.string "build"
      t.integer "height_inches"
      t.integer "weight_lbs"
      t.string "espn_id"
      t.string "espn_headshot_url"
      t.string "team_slug"
      t.string "gsis_id"
      t.string "otc_id"
      t.string "sleeper_id"
      t.string "pfr_id"
      t.string "nflverse_id"
      t.index ["espn_id"], name: "index_athletes_on_espn_id"
      t.index ["gsis_id"], name: "index_athletes_on_gsis_id", unique: true
      t.index ["nflverse_id"], name: "index_athletes_on_nflverse_id", unique: true
      t.index ["otc_id"], name: "index_athletes_on_otc_id", unique: true
      t.index ["person_slug"], name: "index_athletes_on_person_slug", unique: true
      t.index ["pff_id"], name: "index_athletes_on_pff_id", unique: true
      t.index ["pfr_id"], name: "index_athletes_on_pfr_id", unique: true
      t.index ["position"], name: "index_athletes_on_position"
      t.index ["sleeper_id"], name: "index_athletes_on_sleeper_id", unique: true
      t.index ["slug"], name: "index_athletes_on_slug", unique: true
      t.index ["sport"], name: "index_athletes_on_sport"
      t.index ["team_slug"], name: "index_athletes_on_team_slug"
    end
  end
end
