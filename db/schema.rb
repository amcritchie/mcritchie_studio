# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2026_04_20_025622) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "activities", force: :cascade do |t|
    t.string "agent_slug"
    t.string "activity_type"
    t.text "description"
    t.string "task_slug"
    t.jsonb "metadata", default: {}
    t.string "slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["activity_type", "created_at"], name: "index_activities_on_activity_type_and_created_at"
    t.index ["activity_type"], name: "index_activities_on_activity_type"
    t.index ["agent_slug"], name: "index_activities_on_agent_slug"
    t.index ["slug"], name: "index_activities_on_slug", unique: true
    t.index ["task_slug"], name: "index_activities_on_task_slug"
  end

  create_table "agents", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.string "status", default: "active"
    t.text "description"
    t.string "agent_type"
    t.string "title"
    t.jsonb "config", default: {}
    t.jsonb "metadata", default: {}
    t.datetime "last_active_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "avatar"
    t.integer "position", default: 0
    t.index ["slug"], name: "index_agents_on_slug", unique: true
    t.index ["status"], name: "index_agents_on_status"
  end

  create_table "athletes", force: :cascade do |t|
    t.string "person_slug", null: false
    t.string "sport", null: false
    t.string "position"
    t.integer "draft_year"
    t.integer "draft_round"
    t.integer "draft_pick"
    t.string "slug", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["person_slug"], name: "index_athletes_on_person_slug", unique: true
    t.index ["slug"], name: "index_athletes_on_slug", unique: true
    t.index ["sport"], name: "index_athletes_on_sport"
  end

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
    t.index ["slug"], name: "index_contents_on_slug", unique: true
    t.index ["source_news_slug"], name: "index_contents_on_source_news_slug"
    t.index ["stage", "position"], name: "index_contents_on_stage_and_position"
    t.index ["stage"], name: "index_contents_on_stage"
  end

  create_table "contracts", force: :cascade do |t|
    t.string "person_slug", null: false
    t.string "team_slug", null: false
    t.string "slug", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "expires_at"
    t.bigint "annual_value_cents"
    t.string "position"
    t.index ["person_slug", "team_slug"], name: "index_contracts_on_person_slug_and_team_slug", unique: true
    t.index ["person_slug"], name: "index_contracts_on_person_slug"
    t.index ["slug"], name: "index_contracts_on_slug", unique: true
    t.index ["team_slug"], name: "index_contracts_on_team_slug"
  end

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

  create_table "expense_transactions", force: :cascade do |t|
    t.string "slug", null: false
    t.bigint "expense_upload_id", null: false
    t.date "transaction_date", null: false
    t.string "raw_description", null: false
    t.string "normalized_description"
    t.integer "amount_cents", null: false
    t.string "payment_method"
    t.string "status", default: "unreviewed"
    t.string "classification"
    t.string "category"
    t.string "deduction_type"
    t.string "account"
    t.string "vendor"
    t.text "business_description"
    t.text "business_purpose"
    t.text "ai_question"
    t.text "user_answer"
    t.boolean "manually_overridden", default: false
    t.boolean "excluded", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expense_upload_id"], name: "index_expense_transactions_on_expense_upload_id"
    t.index ["payment_method", "amount_cents", "transaction_date"], name: "idx_expense_txn_duplicate_detection"
    t.index ["slug"], name: "index_expense_transactions_on_slug", unique: true
  end

  create_table "expense_uploads", force: :cascade do |t|
    t.string "filename", null: false
    t.string "slug", null: false
    t.string "card_type"
    t.string "status", default: "pending"
    t.integer "transaction_count", default: 0
    t.integer "duplicates_skipped", default: 0
    t.integer "credits_skipped", default: 0
    t.jsonb "processing_summary", default: {}
    t.datetime "processed_at"
    t.datetime "evaluated_at"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "unique_transactions", default: 0
    t.date "first_transaction_at"
    t.date "last_transaction_at"
    t.bigint "payment_method_id"
    t.index ["payment_method_id"], name: "index_expense_uploads_on_payment_method_id"
    t.index ["slug"], name: "index_expense_uploads_on_slug", unique: true
    t.index ["user_id"], name: "index_expense_uploads_on_user_id"
  end

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
    t.text "callback"
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
    t.index ["slug"], name: "index_news_on_slug", unique: true
    t.index ["stage", "position"], name: "index_news_on_stage_and_position"
    t.index ["stage"], name: "index_news_on_stage"
  end

  create_table "payment_methods", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.string "last_four"
    t.string "parser_key"
    t.string "color"
    t.string "logo"
    t.integer "position", default: 0
    t.string "status", default: "active"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "color_secondary"
    t.index ["slug"], name: "index_payment_methods_on_slug", unique: true
    t.index ["user_id"], name: "index_payment_methods_on_user_id"
  end

  create_table "people", force: :cascade do |t|
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "slug", null: false
    t.boolean "athlete", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "aliases", default: []
    t.index ["slug"], name: "index_people_on_slug", unique: true
  end

  create_table "skill_assignments", force: :cascade do |t|
    t.string "agent_slug", null: false
    t.string "skill_slug", null: false
    t.integer "proficiency", default: 100
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["agent_slug", "skill_slug"], name: "index_skill_assignments_on_agent_slug_and_skill_slug", unique: true
    t.index ["agent_slug"], name: "index_skill_assignments_on_agent_slug"
    t.index ["skill_slug"], name: "index_skill_assignments_on_skill_slug"
  end

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

  create_table "tasks", force: :cascade do |t|
    t.string "title", null: false
    t.string "slug", null: false
    t.text "description"
    t.string "stage", default: "new"
    t.integer "priority", default: 0
    t.string "agent_slug"
    t.jsonb "required_skills", default: []
    t.jsonb "result", default: {}
    t.jsonb "metadata", default: {}
    t.text "error_message"
    t.integer "position"
    t.datetime "queued_at"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.datetime "failed_at"
    t.datetime "archived_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["agent_slug"], name: "index_tasks_on_agent_slug"
    t.index ["priority"], name: "index_tasks_on_priority"
    t.index ["slug"], name: "index_tasks_on_slug", unique: true
    t.index ["stage", "created_at"], name: "index_tasks_on_stage_and_created_at"
    t.index ["stage", "position"], name: "index_tasks_on_stage_and_position"
    t.index ["stage"], name: "index_tasks_on_stage"
  end

  create_table "teams", force: :cascade do |t|
    t.string "name", null: false
    t.string "short_name"
    t.string "slug", null: false
    t.string "location"
    t.string "emoji"
    t.string "color_primary"
    t.string "color_secondary"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "color_text_light", default: false
    t.string "sport"
    t.string "league"
    t.string "conference"
    t.string "division"
    t.index ["slug"], name: "index_teams_on_slug", unique: true
    t.index ["sport", "league"], name: "index_teams_on_sport_and_league"
  end

  create_table "theme_settings", force: :cascade do |t|
    t.string "app_name", null: false
    t.string "primary"
    t.string "accent1"
    t.string "accent2"
    t.string "warning"
    t.string "danger"
    t.string "dark"
    t.string "light"
    t.string "slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["app_name"], name: "index_theme_settings_on_app_name", unique: true
  end

  create_table "usages", force: :cascade do |t|
    t.string "agent_slug"
    t.date "period_date", null: false
    t.string "period_type", null: false
    t.string "model"
    t.integer "tokens_in", default: 0
    t.integer "tokens_out", default: 0
    t.integer "api_calls", default: 0
    t.decimal "cost", precision: 10, scale: 4, default: "0.0"
    t.integer "tasks_completed", default: 0
    t.integer "tasks_failed", default: 0
    t.jsonb "metadata", default: {}
    t.string "slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["agent_slug", "period_date", "period_type", "model"], name: "idx_usages_unique", unique: true
    t.index ["agent_slug"], name: "index_usages_on_agent_slug"
    t.index ["slug"], name: "index_usages_on_slug", unique: true
  end

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
    t.date "birth_date"
    t.integer "birth_year"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["slug"], name: "index_users_on_slug", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "expense_transactions", "expense_uploads"
  add_foreign_key "expense_uploads", "payment_methods"
  add_foreign_key "expense_uploads", "users"
  add_foreign_key "payment_methods", "users"
end
