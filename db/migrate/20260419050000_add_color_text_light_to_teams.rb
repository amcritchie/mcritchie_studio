class AddColorTextLightToTeams < ActiveRecord::Migration[7.2]
  def change
    add_column :teams, :color_text_light, :boolean, default: false
  end
end
