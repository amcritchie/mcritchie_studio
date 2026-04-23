class AddAppearanceToAthletes < ActiveRecord::Migration[7.2]
  def change
    add_column :athletes, :skin_tone, :string
    add_column :athletes, :hair_description, :string
    add_column :athletes, :build, :string
    add_column :athletes, :height_inches, :integer
    add_column :athletes, :weight_lbs, :integer
  end
end
