class CreatePeople < ActiveRecord::Migration[7.2]
  def change
    create_table :people do |t|
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :slug, null: false
      t.boolean :athlete, default: false
      t.timestamps
    end

    add_index :people, :slug, unique: true
  end
end
