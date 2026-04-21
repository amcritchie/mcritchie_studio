class AddContractTypeToContracts < ActiveRecord::Migration[7.2]
  def change
    add_column :contracts, :contract_type, :string, default: "active"
    add_index :contracts, :contract_type
  end
end
