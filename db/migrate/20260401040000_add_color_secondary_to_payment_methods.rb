class AddColorSecondaryToPaymentMethods < ActiveRecord::Migration[7.2]
  def change
    add_column :payment_methods, :color_secondary, :string
  end
end
