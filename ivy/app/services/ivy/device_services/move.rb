# Service for moving a device.
#
# Note that this doesn't save the device/chassis.  Currently all callers do
# that afterwards, if that changes we may want to reconsider.
module Ivy
  module DeviceServices
    class Move
      def self.call(location, params, user)
        location.update_position(params)
        if location.rack_id_changed?
          # Ensure that we're authorized to move to the destination rack.
          user.ability.authorize!(:update, location.rack)
        end
      end
    end
  end
end
