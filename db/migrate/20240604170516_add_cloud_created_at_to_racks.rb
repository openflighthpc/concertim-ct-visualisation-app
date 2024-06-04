class AddCloudCreatedAtToRacks < ActiveRecord::Migration[7.1]
  def up
    HwRack.destroy_all
    add_column :racks, :cloud_created_at, :datetime, null: false
  end

  def down
    remove_column :racks, :cloud_created_at, :datetime, null: false
  end
end
