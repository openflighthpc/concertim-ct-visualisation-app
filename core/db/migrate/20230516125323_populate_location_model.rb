class PopulateLocationModel < ActiveRecord::Migration[7.0]
  class Chassis < ActiveRecord::Base
     self.table_name = "base_chassis"
  end

  class Chassis::RackChassis < Chassis
  end

  class ChassisRow < ActiveRecord::Base
    belongs_to :chassis, foreign_key: :base_chassis_id
  end

  class Slot < ActiveRecord::Base
    belongs_to :chassis_row
  end

  class Location < ActiveRecord::Base
    has_one :chassis
  end

  class Device < ActiveRecord::Base
    belongs_to :slot
  end

  class Chassis
    belongs_to :location
  end

  def up
    say "Creating locations for all devices"
    Device.reset_column_information
    Device.all.each do |device|
      chassis = device&.slot&.chassis_row&.chassis
      if chassis.nil?
        say "Skipping device #{device.id}:#{device.name} it has no chassis", true
        next
      end
      location = chassis.build_location(
        depth: chassis.u_depth,
        start_u: chassis.rack_start_u,
        end_u: chassis.rack_end_u,
        facing: chassis.facing,
        rack_id: chassis.rack_id,
      )
      say "Creating location #{location.attributes} for device #{device.id}:#{device.name}", true
      location.save!
      say "Setting device.base_chassis_id for device #{device.id}:#{device.name}", true
      device.base_chassis_id = chassis.id
      device.save!
    end

    change_column_null :base_chassis, :location_id, false
    change_column_null :devices, :base_chassis_id, false
  end

  def down
    say "Deleting locations for all devices"
    change_column_null :base_chassis, :location_id, true
    execute "UPDATE base_chassis SET location_id = NULL"
    Location.destroy_all

    say "Nullifying devices.base_chassis_id for all devices"
    change_column_null :devices, :base_chassis_id, true
    execute "UPDATE devices SET base_chassis_id = NULL"
  end
end
