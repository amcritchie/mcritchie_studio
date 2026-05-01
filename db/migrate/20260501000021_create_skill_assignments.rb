class CreateSkillAssignments < ActiveRecord::Migration[7.2]
  def change
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
  end
end
