class CreateCoaches < ActiveRecord::Migration[7.2]
  def change
    create_table :coaches do |t|
      t.string :person_slug, null: false
      t.string :team_slug, null: false
      t.string :role, null: false
      t.string :lean
      t.string :sport, null: false
      t.string :slug, null: false
      t.timestamps
    end

    add_index :coaches, :slug, unique: true
    add_index :coaches, :person_slug
    add_index :coaches, :team_slug
    add_index :coaches, [:person_slug, :team_slug, :role], unique: true, name: "index_coaches_unique_role"
  end
end
