class CreateContents < ActiveRecord::Migration[7.2]
  def change
    create_table :contents do |t|
      # Pipeline
      t.string  :stage, default: "idea", null: false
      t.integer :position
      t.string  :slug, null: false

      # Idea stage
      t.string  :title, null: false
      t.text    :description
      t.string  :source_type              # "news" or "manual"
      t.string  :source_news_slug         # FK to News (if from concluded article)
      t.string  :content_type, default: "tiktok_video"

      # Hook stage
      t.string  :hook_image_url
      t.jsonb   :hook_ideas, default: []
      t.integer :selected_hook_index

      # Script stage
      t.text    :script_text
      t.integer :duration_seconds
      t.jsonb   :scenes, default: []

      # Assets stage
      t.jsonb   :scene_assets, default: []

      # Assembly stage
      t.string  :final_video_url
      t.string  :music_track
      t.jsonb   :text_overlays, default: []
      t.boolean :logo_overlay, default: true

      # Posted stage
      t.string  :platform, default: "tiktok"
      t.string  :post_url
      t.string  :post_id
      t.datetime :posted_at

      # Reviewed stage
      t.integer :views
      t.integer :likes
      t.integer :comments_count
      t.integer :shares
      t.text    :review_notes

      # Stage timestamps
      t.datetime :hooked_at
      t.datetime :scripted_at
      t.datetime :asset_at
      t.datetime :assembled_at
      t.datetime :reviewed_at

      t.timestamps
    end

    add_index :contents, :slug, unique: true
    add_index :contents, :stage
    add_index :contents, [:stage, :position]
    add_index :contents, :source_news_slug
  end
end
