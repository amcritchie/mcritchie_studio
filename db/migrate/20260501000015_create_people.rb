class CreatePeople < ActiveRecord::Migration[7.2]
  def change
    create_table "people", force: :cascade do |t|
      t.string "first_name", null: false
      t.string "last_name", null: false
      t.string "slug", null: false
      t.boolean "athlete", default: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.jsonb "aliases", default: []
      t.boolean "coach", default: false
      t.index ["last_name", "first_name"], name: "index_people_on_last_name_and_first_name"
      t.index ["slug"], name: "index_people_on_slug", unique: true
    end
  end
end
