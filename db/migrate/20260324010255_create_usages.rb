class CreateUsages < ActiveRecord::Migration[7.2]
  def change
    create_table :usages do |t|
      t.string :agent_slug
      t.date :period_date, null: false
      t.string :period_type, null: false
      t.string :model
      t.integer :tokens_in, default: 0
      t.integer :tokens_out, default: 0
      t.integer :api_calls, default: 0
      t.decimal :cost, precision: 10, scale: 4, default: 0
      t.integer :tasks_completed, default: 0
      t.integer :tasks_failed, default: 0
      t.jsonb :metadata, default: {}
      t.string :slug

      t.timestamps
    end

    add_index :usages, [:agent_slug, :period_date, :period_type, :model], unique: true, name: "idx_usages_unique"
    add_index :usages, :agent_slug
    add_index :usages, :slug, unique: true
  end
end
