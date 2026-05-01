class CreateImageCaches < ActiveRecord::Migration[7.2]
  def change
    create_table "image_caches", force: :cascade do |t|
      t.string "owner_type", null: false
      t.bigint "owner_id", null: false
      t.string "purpose", null: false
      t.string "variant", null: false
      t.string "s3_key", null: false
      t.string "source_url"
      t.integer "bytes"
      t.string "content_type"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["owner_type", "owner_id", "purpose", "variant"], name: "idx_image_caches_owner_purpose_variant", unique: true
      t.index ["owner_type", "owner_id"], name: "index_image_caches_on_owner"
      t.index ["s3_key"], name: "index_image_caches_on_s3_key", unique: true
    end
  end
end
