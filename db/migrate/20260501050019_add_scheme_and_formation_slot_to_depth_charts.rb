class AddSchemeAndFormationSlotToDepthCharts < ActiveRecord::Migration[7.2]
  def change
    add_column :depth_charts, :scheme, :string
    add_column :depth_chart_entries, :formation_slot, :string
    add_index :depth_chart_entries, :formation_slot
  end
end
