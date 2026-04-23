class AddVideoProductionToContents < ActiveRecord::Migration[7.2]
  def change
    add_column :contents, :reference_video_url, :string
    add_column :contents, :reference_video_start, :integer
    add_column :contents, :reference_video_end, :integer
    add_column :contents, :rival_team_slug, :string
    add_column :contents, :captions, :text
    add_column :contents, :hashtags, :jsonb, default: []
    add_column :contents, :music_suggestions, :jsonb, default: []
    add_index :contents, :rival_team_slug
  end
end
