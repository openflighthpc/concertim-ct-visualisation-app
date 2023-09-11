class RacksAreNotDevices < ActiveRecord::Migration[7.0]
  module Ivy
    class DataSourceMap < ActiveRecord::Base
      self.table_name = "data_source_maps"
    end

    class Device < ActiveRecord::Base
      self.store_full_sti_class = false
      self.table_name = "devices"
      has_one :data_source_map
    end

    class Device::RackTaggedDevice < Device
    end

    class HwRack < ActiveRecord::Base
      self.table_name = "racks"

      belongs_to :tagged_device,
        class_name: "RacksAreNotDevices::Ivy::Device::RackTaggedDevice"
    end
  end

  def change
    change_column_null :racks, :tagged_device_id, true

    reversible do |dir|
      dir.up do
        say "Removing rack tagged devices"
        Ivy::HwRack.reset_column_information
        Ivy::HwRack.all.each do |rack|
          if rack.tagged_device.nil?
            say "Tagged device for #{rack.id}:#{rack.name} not found"
          else
            say "Removing tagged device for #{rack.id}:#{rack.name}"
            rack.tagged_device.destroy!
          end
        end
      end

      dir.down do
        say "Adding rack tagged devices"
        Ivy::HwRack.reset_column_information
        Ivy::HwRack.all.each do |rack|
          if !rack.tagged_device.nil?
            say "Skipping rack #{rack.id}:#{rack.name} already has a tagged device"
            next
          end
          say "Adding tagged device for rack #{rack.id}:#{rack.name}"
          tagged_device = rack.build_tagged_device
          tagged_device.tagged = true
          tagged_device.name ||= rack.name
          tagged_device.build_data_source_map(
            map_to_grid: "unspecified",
            map_to_cluster: "unspecified",
            map_to_host: "tagdev-#{Time.now.to_f}-#{rack.name}"
          )
          rack.save!
        end
      end
    end

    change_table :racks do |t|
      t.remove :tagged_device_id, type: :integer, null: true
    end
  end
end
