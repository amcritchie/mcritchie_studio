class CreateNews < ActiveRecord::Migration[7.2]
  def change
    create_table :news do |t|
      # Pipeline
      t.string  :stage, default: "new", null: false
      t.integer :position
      t.string  :slug, null: false

      # Source (New stage)
      t.string   :title, null: false
      t.string   :url
      t.string   :x_post_id
      t.string   :x_post_url
      t.string   :author
      t.datetime :published_at

      # Reviewed (Mason)
      t.string :primary_person
      t.string :primary_team
      t.string :primary_action
      t.string :secondary_person
      t.string :secondary_team
      t.string :article_image_url

      # Processed (Mack)
      t.string :primary_person_slug
      t.string :primary_team_slug
      t.string :secondary_person_slug
      t.string :secondary_team_slug

      # Refined (Alex)
      t.string :title_short
      t.text   :summary
      t.string :feeling
      t.string :feeling_emoji
      t.string :what_happened

      # Concluded (Turf Monster)
      t.text :opinion
      t.text :callback

      # Stage timestamps
      t.datetime :reviewed_at
      t.datetime :processed_at
      t.datetime :refined_at
      t.datetime :concluded_at
      t.datetime :archived_at

      t.timestamps
    end

    add_index :news, :slug, unique: true
    add_index :news, :stage
    add_index :news, [:stage, :position]
    add_index :news, :primary_person_slug
    add_index :news, :primary_team_slug
  end
end
