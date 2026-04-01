class AddTransactionDateRangeToExpenseUploads < ActiveRecord::Migration[7.2]
  def change
    add_column :expense_uploads, :first_transaction_at, :date
    add_column :expense_uploads, :last_transaction_at, :date
  end
end
