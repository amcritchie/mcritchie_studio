class CreateSlates < ActiveRecord::Migration[7.2]
  def change
    create_table :slates do |t|
      t.string :season_slug, null: false
      t.integer :sequence, null: false
      t.string :label, null: false
      t.string :slate_type, null: false
      t.date :starts_at
      t.date :ends_at
      t.string :slug, null: false

      t.timestamps
    end

    add_index :slates, :slug, unique: true
    add_index :slates, :season_slug
    add_index :slates, [:season_slug, :sequence], unique: true
  end
end
