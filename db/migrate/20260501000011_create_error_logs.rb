class CreateErrorLogs < ActiveRecord::Migration[7.2]
  def change
    create_table "error_logs", force: :cascade do |t|
      t.text "message"
      t.text "inspect"
      t.text "backtrace"
      t.string "target_type"
      t.bigint "target_id"
      t.string "parent_type"
      t.bigint "parent_id"
      t.string "target_name"
      t.string "parent_name"
      t.string "slug"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["parent_type", "parent_id"], name: "index_error_logs_on_parent_type_and_parent_id"
      t.index ["slug"], name: "index_error_logs_on_slug", unique: true
      t.index ["target_type", "target_id"], name: "index_error_logs_on_target_type_and_target_id"
    end
  end
end
