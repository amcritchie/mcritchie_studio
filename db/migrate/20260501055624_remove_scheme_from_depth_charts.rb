class RemoveSchemeFromDepthCharts < ActiveRecord::Migration[7.2]
  def change
    remove_column :depth_charts, :scheme, :string
  end
end
