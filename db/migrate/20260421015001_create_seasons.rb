class CreateSeasons < ActiveRecord::Migration[7.2]
  def change
    create_table :seasons do |t|
      t.integer :year, null: false
      t.string :sport, null: false
      t.string :league, null: false
      t.string :name, null: false
      t.boolean :active, default: false
      t.string :slug, null: false

      t.timestamps
    end

    add_index :seasons, :slug, unique: true
    add_index :seasons, [:year, :league], unique: true
    add_index :seasons, [:league, :active]
  end
end
