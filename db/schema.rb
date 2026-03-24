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

ActiveRecord::Schema[7.2].define(version: 2026_03_24_031043) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "activities", force: :cascade do |t|
    t.string "agent_slug"
    t.string "activity_type"
    t.text "description"
    t.string "task_slug"
    t.jsonb "metadata", default: {}
    t.string "slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.string "avatar_url"
    t.string "agent_type"
    t.string "title"
    t.jsonb "config", default: {}
    t.jsonb "metadata", default: {}
    t.datetime "last_active_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_agents_on_slug", unique: true
    t.index ["status"], name: "index_agents_on_status"
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
    t.index ["stage"], name: "index_tasks_on_stage"
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
end
