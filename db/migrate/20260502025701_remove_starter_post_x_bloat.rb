class RemoveStarterPostXBloat < ActiveRecord::Migration[7.2]
  def change
    remove_index  :contents, :correct_player_slug, if_exists: true
    remove_column :contents, :correct_player_slug, :string
    remove_column :contents, :mistake_slot, :string
    remove_column :contents, :hook_caption, :text
  end
end
