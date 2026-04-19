class CreateContracts < ActiveRecord::Migration[7.2]
  def change
    create_table :contracts do |t|
      t.string :person_slug, null: false
      t.string :team_slug, null: false
      t.string :slug, null: false
      t.timestamps
    end

    add_index :contracts, :slug, unique: true
    add_index :contracts, :person_slug
    add_index :contracts, :team_slug
    add_index :contracts, [:person_slug, :team_slug], unique: true
  end
end
