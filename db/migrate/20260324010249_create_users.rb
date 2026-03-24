class CreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users do |t|
      t.string :name
      t.string :email, null: false
      t.string :password_digest
      t.string :provider
      t.string :uid
      t.string :role, default: "viewer"
      t.string :slug

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :slug, unique: true
  end
end
