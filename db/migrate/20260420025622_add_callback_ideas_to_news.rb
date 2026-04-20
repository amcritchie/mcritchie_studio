class AddCallbackIdeasToNews < ActiveRecord::Migration[7.2]
  def change
    add_column :news, :callback_ideas, :jsonb, default: []
  end
end
