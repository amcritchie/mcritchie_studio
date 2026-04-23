class AddPffIdToAthletes < ActiveRecord::Migration[7.2]
  def change
    add_column :athletes, :pff_id, :integer
    add_index :athletes, :pff_id, unique: true
  end
end
