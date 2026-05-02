class AddHashtag2AndXHandleToTeams < ActiveRecord::Migration[7.2]
  def change
    add_column :teams, :hashtag2,  :string
    add_column :teams, :x_handle,  :string
  end
end
