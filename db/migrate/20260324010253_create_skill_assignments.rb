class CreateSkillAssignments < ActiveRecord::Migration[7.2]
  def change
    create_table :skill_assignments do |t|
      t.string :agent_slug, null: false
      t.string :skill_slug, null: false
      t.integer :proficiency, default: 100

      t.timestamps
    end

    add_index :skill_assignments, [:agent_slug, :skill_slug], unique: true
    add_index :skill_assignments, :agent_slug
    add_index :skill_assignments, :skill_slug
  end
end
