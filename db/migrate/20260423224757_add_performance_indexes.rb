class AddPerformanceIndexes < ActiveRecord::Migration[7.2]
  def change
    add_index :people, [:last_name, :first_name]
    add_index :athletes, :position
    add_index :contracts, :expires_at
    add_index :news, :secondary_person_slug
    add_index :news, :secondary_team_slug
    add_index :coaches, :sport
  end
end
