class ChassisAreNotDevices < ActiveRecord::Migration[7.0]
  module Ivy
    class Device < ActiveRecord::Base
      self.store_full_sti_class = false
      self.table_name = "devices"
    end

    class Device::ChassisTaggedDevice < Device
    end
  end

  def change
    reversible do |dir|
      dir.up   { execute 'SET search_path TO ivy,public' }
    end

    reversible do |dir|
      dir.up do
        say "Removing chassis tagged devices"
        Ivy::Device::ChassisTaggedDevice.reset_column_information
        Ivy::Device::ChassisTaggedDevice.destroy_all
      end

      dir.down do
        # Nothing to do here.  We were already not allowing complex chassis and
        # hence were not allowing chassis tagged devices.
      end
    end

    remove_reference 'devices', 'base_chassis',
      null: true,
      foreign_key: { on_update: :cascade, on_delete: :cascade }

    reversible do |dir|
      dir.down { execute 'SET search_path TO ivy,public' }
    end
  end
end
