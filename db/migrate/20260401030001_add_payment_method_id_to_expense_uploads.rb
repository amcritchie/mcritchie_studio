class AddPaymentMethodIdToExpenseUploads < ActiveRecord::Migration[7.2]
  def change
    add_reference :expense_uploads, :payment_method, foreign_key: true
  end
end
