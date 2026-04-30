class CreateDepthCharts < ActiveRecord::Migration[7.2]
  def change
    create_table :depth_charts do |t|
      t.string :team_slug, null: false
      t.string :slug, null: false
      t.timestamps
    end
    add_index :depth_charts, :team_slug, unique: true
    add_index :depth_charts, :slug, unique: true

    create_table :depth_chart_entries do |t|
      t.string :depth_chart_slug, null: false
      t.string :person_slug, null: false
      t.string :position, null: false
      t.string :side, null: false
      t.integer :depth, null: false
      t.boolean :locked, null: false, default: false
      t.timestamps
    end
    add_index :depth_chart_entries, :depth_chart_slug
    add_index :depth_chart_entries, [:depth_chart_slug, :person_slug, :position], unique: true, name: "idx_dce_unique"
    add_index :depth_chart_entries, [:depth_chart_slug, :position, :depth]
  end
end
