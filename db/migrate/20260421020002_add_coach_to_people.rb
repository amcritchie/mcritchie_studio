class AddCoachToPeople < ActiveRecord::Migration[7.2]
  def change
    add_column :people, :coach, :boolean, default: false
  end
end
