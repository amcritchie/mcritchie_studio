class AddAvatarToAgents < ActiveRecord::Migration[7.2]
  def change
    add_column :agents, :avatar, :string
  end
end
