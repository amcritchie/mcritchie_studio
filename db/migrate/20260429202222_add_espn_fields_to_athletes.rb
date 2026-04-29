class AddEspnFieldsToAthletes < ActiveRecord::Migration[7.2]
  def change
    add_column :athletes, :espn_id, :string
    add_index :athletes, :espn_id
    add_column :athletes, :espn_headshot_url, :string
  end
end
