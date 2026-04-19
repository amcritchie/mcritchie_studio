class AddAliasesToPeople < ActiveRecord::Migration[7.2]
  def change
    add_column :people, :aliases, :jsonb, default: []
  end
end
