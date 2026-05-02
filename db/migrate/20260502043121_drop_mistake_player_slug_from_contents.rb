class DropMistakePlayerSlugFromContents < ActiveRecord::Migration[7.2]
  def change
    remove_index  :contents, :mistake_player_slug, if_exists: true
    remove_column :contents, :mistake_player_slug, :string
  end
end
