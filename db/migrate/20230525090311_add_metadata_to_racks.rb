class AddMetadataToRacks < ActiveRecord::Migration[7.0]
  def change
    add_column :racks, :metadata, :jsonb, default: {}, null: false
  end
end
