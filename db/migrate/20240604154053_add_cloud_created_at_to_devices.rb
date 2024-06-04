class AddCloudCreatedAtToDevices < ActiveRecord::Migration[7.1]
  def up
    Chassis.destroy_all
    add_column :devices, :cloud_created_at, :datetime, null: false
  end

  def down
    remove_column :devices, :cloud_created_at, :datetime, null: false
  end
end
