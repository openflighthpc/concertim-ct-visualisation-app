# Service for moving a device.
#
# Note that this doesn't save the device/chassis.  Currently all callers do
# that afterwards, if that changes we may want to reconsider.
#
# Currently, this operates on the chassis, but that is only because the domain
# model still has legacy aspects to it.
module Ivy
  module DeviceServices
    class Move
      def self.call(chassis, params, user)
        chassis = chassis.indirect_chassis if chassis.is_a?(Ivy::Device)
        chassis.update_position(params)
        if chassis.rack_id_changed?
          # Ensure that we're authorized to move the destination rack.
          user.ability.authorize!(:update, chassis.rack)
        end
      end
    end
  end
end
