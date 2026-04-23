class DropExpenseTablesAndDeadColumns < ActiveRecord::Migration[7.2]
  def change
    # Drop dead tables (expense_transactions has FK to expense_uploads, which has FK to payment_methods)
    drop_table :expense_transactions do |t|
      t.string "slug", null: false
      t.bigint "expense_upload_id", null: false
      t.date "transaction_date", null: false
      t.string "raw_description", null: false
      t.string "normalized_description"
      t.integer "amount_cents", null: false
      t.string "payment_method"
      t.string "status", default: "unreviewed"
      t.string "classification"
      t.string "category"
      t.string "deduction_type"
      t.string "account"
      t.string "vendor"
      t.text "business_description"
      t.text "business_purpose"
      t.text "ai_question"
      t.text "user_answer"
      t.boolean "manually_overridden", default: false
      t.boolean "excluded", default: false
      t.timestamps
      t.index ["expense_upload_id"]
      t.index ["payment_method", "amount_cents", "transaction_date"], name: "idx_expense_txn_duplicate_detection"
      t.index ["slug"], unique: true
    end

    drop_table :expense_uploads do |t|
      t.string "filename", null: false
      t.string "slug", null: false
      t.string "card_type"
      t.string "status", default: "pending"
      t.integer "transaction_count", default: 0
      t.integer "duplicates_skipped", default: 0
      t.integer "credits_skipped", default: 0
      t.jsonb "processing_summary", default: {}
      t.datetime "processed_at"
      t.datetime "evaluated_at"
      t.bigint "user_id"
      t.integer "unique_transactions", default: 0
      t.date "first_transaction_at"
      t.date "last_transaction_at"
      t.bigint "payment_method_id"
      t.timestamps
      t.index ["payment_method_id"]
      t.index ["slug"], unique: true
      t.index ["user_id"]
    end

    drop_table :payment_methods do |t|
      t.string "name", null: false
      t.string "slug", null: false
      t.string "last_four"
      t.string "parser_key"
      t.string "color"
      t.string "logo"
      t.integer "position", default: 0
      t.string "status", default: "active"
      t.bigint "user_id"
      t.string "color_secondary"
      t.timestamps
      t.index ["slug"], unique: true
      t.index ["user_id"]
    end

    # Drop orphaned columns
    remove_column :news, :callback, :text
    remove_column :users, :birth_date, :date
    remove_column :users, :birth_year, :integer
  end
end
