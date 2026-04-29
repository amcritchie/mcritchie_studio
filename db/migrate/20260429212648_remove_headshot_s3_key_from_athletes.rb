class RemoveHeadshotS3KeyFromAthletes < ActiveRecord::Migration[7.2]
  def change
    remove_column :athletes, :headshot_s3_key, :string
  end
end
