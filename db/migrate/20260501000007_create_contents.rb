class CreateContents < ActiveRecord::Migration[7.2]
  def change
    create_table "contents", force: :cascade do |t|
      t.string "stage", default: "idea", null: false
      t.integer "position"
      t.string "slug", null: false
      t.string "title", null: false
      t.text "description"
      t.string "source_type"
      t.string "source_news_slug"
      t.string "content_type", default: "tiktok_video"
      t.string "hook_image_url"
      t.jsonb "hook_ideas", default: []
      t.integer "selected_hook_index"
      t.text "script_text"
      t.integer "duration_seconds"
      t.jsonb "scenes", default: []
      t.jsonb "scene_assets", default: []
      t.string "final_video_url"
      t.string "music_track"
      t.jsonb "text_overlays", default: []
      t.boolean "logo_overlay", default: true
      t.string "platform", default: "tiktok"
      t.string "post_url"
      t.string "post_id"
      t.datetime "posted_at"
      t.integer "views"
      t.integer "likes"
      t.integer "comments_count"
      t.integer "shares"
      t.text "review_notes"
      t.datetime "hooked_at"
      t.datetime "scripted_at"
      t.datetime "asset_at"
      t.datetime "assembled_at"
      t.datetime "reviewed_at"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.string "reference_video_url"
      t.integer "reference_video_start"
      t.integer "reference_video_end"
      t.string "rival_team_slug"
      t.text "captions"
      t.jsonb "hashtags", default: []
      t.jsonb "music_suggestions", default: []
      t.index ["rival_team_slug"], name: "index_contents_on_rival_team_slug"
      t.index ["slug"], name: "index_contents_on_slug", unique: true
      t.index ["source_news_slug"], name: "index_contents_on_source_news_slug"
      t.index ["stage", "position"], name: "index_contents_on_stage_and_position"
      t.index ["stage"], name: "index_contents_on_stage"
    end
  end
end
