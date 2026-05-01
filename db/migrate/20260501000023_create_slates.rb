class CreateSlates < ActiveRecord::Migration[7.2]
  def change
    create_table "slates", force: :cascade do |t|
      t.string "season_slug", null: false
      t.integer "sequence", null: false
      t.string "label", null: false
      t.string "slate_type", null: false
      t.date "starts_at"
      t.date "ends_at"
      t.string "slug", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["season_slug", "sequence"], name: "index_slates_on_season_slug_and_sequence", unique: true
      t.index ["season_slug"], name: "index_slates_on_season_slug"
      t.index ["slug"], name: "index_slates_on_slug", unique: true
    end
  end
end
