class CreateRosterSpots < ActiveRecord::Migration[7.2]
  def change
    create_table :roster_spots do |t|
      t.references :roster, null: false, foreign_key: true
      t.string :person_slug, null: false
      t.string :position, null: false
      t.string :side, null: false
      t.integer :depth, null: false, default: 1

      t.timestamps
    end

    add_index :roster_spots, :person_slug
    add_index :roster_spots, [:roster_id, :position, :depth], unique: true
  end
end
