class AddMetadataToDevice < ActiveRecord::Migration[7.0]
  def change
    add_column :devices, :metadata, :jsonb, default: {}, null: false
  end
end
