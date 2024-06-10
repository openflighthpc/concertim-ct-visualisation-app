class AddCloudCreatedAtToRacks < ActiveRecord::Migration[7.1]
  class HwRack < ApplicationRecord
    self.table_name = "racks"
  end

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
    HwRack.destroy_all
    add_column :racks, :cloud_created_at, :datetime, null: false
  end

  def down
    remove_column :racks, :cloud_created_at, :datetime, null: false
  end
end
