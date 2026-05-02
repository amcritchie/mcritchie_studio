class AddStarterPostXFieldsToContents < ActiveRecord::Migration[7.2]
  def change
    add_column :contents, :workflow, :string, default: "video", null: false
    add_column :contents, :team_slug, :string
    add_column :contents, :mistake_slot, :string
    add_column :contents, :mistake_player_slug, :string
    add_column :contents, :correct_player_slug, :string
    add_column :contents, :hook_caption, :text

    add_index :contents, :workflow
    add_index :contents, :team_slug
    add_index :contents, :mistake_player_slug
    add_index :contents, :correct_player_slug
  end
end
