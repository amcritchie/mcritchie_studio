class AddUniqueTransactionsToExpenseUploads < ActiveRecord::Migration[7.2]
  def change
    add_column :expense_uploads, :unique_transactions, :integer, default: 0
  end
end
