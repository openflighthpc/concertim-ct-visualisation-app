class AddCloudCreatedAtToDevices < ActiveRecord::Migration[7.1]
  class Chassis < ApplicationRecord
    self.table_name = "base_chassis"
  end

  class Device < ApplicationRecord
  end

  class Location < ApplicationRecord
  end

  def up
    Device.destroy_all
    Location.destroy_all
    Chassis.destroy_all
    add_column :devices, :cloud_created_at, :datetime, null: false
  end

  def down
    remove_column :devices, :cloud_created_at, :datetime, null: false
  end
end
