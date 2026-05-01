class AddWebsiteColumnsToTeams < ActiveRecord::Migration[7.2]
  def change
    add_column :teams, :team_website, :string
    add_column :teams, :coaches_url, :string
  end
end
