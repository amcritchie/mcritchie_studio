class AddHashtagToTeams < ActiveRecord::Migration[7.2]
  def change
    add_column :teams, :hashtag, :string
  end
end
