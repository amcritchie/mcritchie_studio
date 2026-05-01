class CreateRosters < ActiveRecord::Migration[7.2]
  def change
    create_table "rosters", force: :cascade do |t|
      t.string "team_slug", null: false
      t.string "slate_slug", null: false
      t.string "slug", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["slate_slug"], name: "index_rosters_on_slate_slug"
      t.index ["slug"], name: "index_rosters_on_slug", unique: true
      t.index ["team_slug", "slate_slug"], name: "index_rosters_on_team_slug_and_slate_slug", unique: true
      t.index ["team_slug"], name: "index_rosters_on_team_slug"
    end
  end
end
