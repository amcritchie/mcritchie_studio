class AddEspnFieldsToCoaches < ActiveRecord::Migration[7.2]
  def change
    add_column :coaches, :espn_id, :string
    add_index :coaches, :espn_id
    add_column :coaches, :espn_headshot_url, :string
  end
end
