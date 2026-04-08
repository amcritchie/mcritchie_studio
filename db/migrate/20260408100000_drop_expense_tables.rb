class DropExpenseTables < ActiveRecord::Migration[7.2]
  def up
    drop_table :expense_transactions, if_exists: true
    drop_table :expense_uploads, if_exists: true
    drop_table :expense_guides, if_exists: true
    drop_table :payment_methods, if_exists: true
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
