class CreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table "users", force: :cascade do |t|
      t.string "name"
      t.string "email", null: false
      t.string "password_digest"
      t.string "provider"
      t.string "uid"
      t.string "role", default: "viewer"
      t.string "slug"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.string "first_name"
      t.string "last_name"
      t.index ["email"], name: "index_users_on_email", unique: true
      t.index ["slug"], name: "index_users_on_slug", unique: true
    end
  end
end
