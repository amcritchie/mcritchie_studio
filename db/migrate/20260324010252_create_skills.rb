class CreateSkills < ActiveRecord::Migration[7.2]
  def change
    create_table :skills do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :category
      t.text :description
      t.jsonb :config, default: {}

      t.timestamps
    end

    add_index :skills, :slug, unique: true
    add_index :skills, :category
  end
end
