class CreateExpenseUploads < ActiveRecord::Migration[7.2]
  def change
    create_table :expense_uploads do |t|
      t.string :filename, null: false
      t.string :slug, null: false
      t.string :card_type
      t.string :status, default: "pending"
      t.integer :transaction_count, default: 0
      t.integer :duplicates_skipped, default: 0
      t.integer :credits_skipped, default: 0
      t.jsonb :processing_summary, default: {}
      t.datetime :processed_at
      t.datetime :evaluated_at
      t.references :user, foreign_key: true

      t.timestamps
    end

    add_index :expense_uploads, :slug, unique: true
  end
end
