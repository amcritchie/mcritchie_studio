class CreateRosterSpots < ActiveRecord::Migration[7.2]
  def change
    create_table "roster_spots", force: :cascade do |t|
      t.bigint "roster_id", null: false
      t.string "person_slug", null: false
      t.string "position", null: false
      t.string "side", null: false
      t.integer "depth", default: 1, null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["person_slug"], name: "index_roster_spots_on_person_slug"
      t.index ["roster_id", "position", "depth"], name: "index_roster_spots_on_roster_id_and_position_and_depth", unique: true
      t.index ["roster_id"], name: "index_roster_spots_on_roster_id"
    end
  end
end
