class AddCaptionVariantsToContents < ActiveRecord::Migration[7.2]
  def change
    add_column :contents, :caption_variants, :jsonb, default: []
  end
end
