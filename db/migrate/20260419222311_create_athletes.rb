class CreateAthletes < ActiveRecord::Migration[7.2]
  def change
    create_table :athletes do |t|
      t.string :person_slug, null: false
      t.string :sport, null: false
      t.string :position
      t.integer :draft_year
      t.integer :draft_round
      t.integer :draft_pick
      t.string :slug, null: false
      t.timestamps
    end

    add_index :athletes, :person_slug, unique: true
    add_index :athletes, :slug, unique: true
    add_index :athletes, :sport
  end
end
