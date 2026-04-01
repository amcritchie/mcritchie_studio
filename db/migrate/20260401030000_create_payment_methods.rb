class CreatePaymentMethods < ActiveRecord::Migration[7.2]
  def change
    create_table :payment_methods do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :last_four
      t.string :parser_key
      t.string :color
      t.string :logo
      t.integer :position, default: 0
      t.string :status, default: "active"
      t.references :user, foreign_key: true

      t.timestamps
    end

    add_index :payment_methods, :slug, unique: true
  end
end
