class CreateExpenseTransactions < ActiveRecord::Migration[7.2]
  def change
    create_table :expense_transactions do |t|
      t.string :slug, null: false
      t.references :expense_upload, null: false, foreign_key: true
      t.date :transaction_date, null: false
      t.string :raw_description, null: false
      t.string :normalized_description
      t.integer :amount_cents, null: false
      t.string :payment_method
      t.string :status, default: "unreviewed"

      # AI classification
      t.string :classification
      t.string :category
      t.string :deduction_type
      t.string :account
      t.string :vendor
      t.text :business_description
      t.text :business_purpose
      t.text :ai_question
      t.text :user_answer
      t.boolean :manually_overridden, default: false
      t.boolean :excluded, default: false

      t.timestamps
    end

    add_index :expense_transactions, :slug, unique: true
    add_index :expense_transactions, [:payment_method, :amount_cents, :transaction_date], name: "idx_expense_txn_duplicate_detection"
  end
end
