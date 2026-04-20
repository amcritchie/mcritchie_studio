class AddFieldsToContracts < ActiveRecord::Migration[7.2]
  def change
    add_column :contracts, :expires_at, :date
    add_column :contracts, :annual_value_cents, :bigint
    add_column :contracts, :position, :string
  end
end
