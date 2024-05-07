class AddTypeToDevices < ActiveRecord::Migration[7.1]
  class Device < ApplicationRecord
  end

  def up
    add_column :devices, :type, :string

    Device.where(details_type: "Device::ComputeDetails").update_all(type: "Instance")
    Device.where(details_type: "Device::NetworkDetails").update_all(type: "Network")
    Device.where(details_type: "Device::VolumeDetails").update_all(type: "Volume")

    change_column_null :devices, :type, false
    add_index :devices, :type
  end

  def down
    remove_column :devices, :type
  end
end
