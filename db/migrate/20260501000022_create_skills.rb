class CreateSkills < ActiveRecord::Migration[7.2]
  def change
    create_table "skills", force: :cascade do |t|
      t.string "name", null: false
      t.string "slug", null: false
      t.string "category"
      t.text "description"
      t.jsonb "config", default: {}
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["category"], name: "index_skills_on_category"
      t.index ["slug"], name: "index_skills_on_slug", unique: true
    end
  end
end
