class RacksAreNotDevices < ActiveRecord::Migration[7.0]
  class DataSourceMap < ActiveRecord::Base
  end

  class Device < ActiveRecord::Base
    has_one :data_source_map
  end

  class Device::RackTaggedDevice < Device
  end

  class HwRack < ActiveRecord::Base
    self.table_name = "racks"

    belongs_to :tagged_device,
      class_name: "RacksAreNotDevices::Device::RackTaggedDevice"
  end

  def change
    change_column_null :racks, :tagged_device_id, true

    reversible do |dir|
      dir.up do
        say "Removing rack tagged devices"
        HwRack.reset_column_information
        HwRack.all.each do |rack|
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
        HwRack.reset_column_information
        HwRack.all.each do |rack|
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
