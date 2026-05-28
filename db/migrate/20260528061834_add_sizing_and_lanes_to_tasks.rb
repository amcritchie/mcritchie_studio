class AddSizingAndLanesToTasks < ActiveRecord::Migration[7.2]
  def change
    change_table :tasks, bulk: true do |t|
      t.string   :pm_size
      t.string   :po_size
      t.string   :dev_size
      t.string   :actual_size
      t.datetime :sizes_revealed_at
      t.boolean  :requires_migration, default: false, null: false
    end
    add_index :tasks, :requires_migration
  end
end
