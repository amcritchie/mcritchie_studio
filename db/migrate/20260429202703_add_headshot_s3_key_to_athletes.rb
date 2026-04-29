class AddHeadshotS3KeyToAthletes < ActiveRecord::Migration[7.2]
  def change
    add_column :athletes, :headshot_s3_key, :string
  end
end
