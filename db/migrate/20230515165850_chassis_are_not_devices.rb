class ChassisAreNotDevices < ActiveRecord::Migration[7.0]
  class Device < ActiveRecord::Base
  end

  class Device::ChassisTaggedDevice < Device
  end

  def change
    reversible do |dir|
      dir.up do
        say "Removing chassis tagged devices"
        Device::ChassisTaggedDevice.reset_column_information
        Device::ChassisTaggedDevice.destroy_all
      end

      dir.down do
        # Nothing to do here.  We were already not allowing complex chassis and
        # hence were not allowing chassis tagged devices.
      end
    end

    remove_reference 'devices', 'base_chassis',
      null: true,
      foreign_key: { on_update: :cascade, on_delete: :cascade }
  end
end
