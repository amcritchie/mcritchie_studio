class AddPositionToAgents < ActiveRecord::Migration[7.2]
  def change
    add_column :agents, :position, :integer, default: 0
  end
end
