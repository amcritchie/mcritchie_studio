class RemoveAvatarUrlFromAgents < ActiveRecord::Migration[7.2]
  def change
    remove_column :agents, :avatar_url, :string
  end
end
