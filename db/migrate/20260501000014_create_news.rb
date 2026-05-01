class CreateNews < ActiveRecord::Migration[7.2]
  def change
    create_table "news", force: :cascade do |t|
      t.string "stage", default: "new", null: false
      t.integer "position"
      t.string "slug", null: false
      t.string "title", null: false
      t.string "url"
      t.string "x_post_id"
      t.string "x_post_url"
      t.string "author"
      t.datetime "published_at"
      t.string "primary_person"
      t.string "primary_team"
      t.string "primary_action"
      t.string "secondary_person"
      t.string "secondary_team"
      t.string "article_image_url"
      t.string "primary_person_slug"
      t.string "primary_team_slug"
      t.string "secondary_person_slug"
      t.string "secondary_team_slug"
      t.string "title_short"
      t.text "summary"
      t.string "feeling"
      t.string "feeling_emoji"
      t.string "what_happened"
      t.text "opinion"
      t.datetime "reviewed_at"
      t.datetime "processed_at"
      t.datetime "refined_at"
      t.datetime "concluded_at"
      t.datetime "archived_at"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.jsonb "callback_ideas", default: []
      t.index ["primary_person_slug"], name: "index_news_on_primary_person_slug"
      t.index ["primary_team_slug"], name: "index_news_on_primary_team_slug"
      t.index ["secondary_person_slug"], name: "index_news_on_secondary_person_slug"
      t.index ["secondary_team_slug"], name: "index_news_on_secondary_team_slug"
      t.index ["slug"], name: "index_news_on_slug", unique: true
      t.index ["stage", "position"], name: "index_news_on_stage_and_position"
      t.index ["stage"], name: "index_news_on_stage"
    end
  end
end
