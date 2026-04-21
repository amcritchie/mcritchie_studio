class CreateRosters < ActiveRecord::Migration[7.2]
  def change
    create_table :rosters do |t|
      t.string :team_slug, null: false
      t.string :slate_slug, null: false
      t.string :slug, null: false

      t.timestamps
    end

    add_index :rosters, :slug, unique: true
    add_index :rosters, :team_slug
    add_index :rosters, :slate_slug
    add_index :rosters, [:team_slug, :slate_slug], unique: true
  end
end
