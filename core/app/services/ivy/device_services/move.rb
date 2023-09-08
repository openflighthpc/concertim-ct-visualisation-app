# Service for moving a device.
#
# Note that this doesn't save the device/chassis.  Currently all callers do
# that afterwards, if that changes we may want to reconsider.
module Ivy
  module DeviceServices
    class Move
      def self.call(location, params, user)
        location.update_position(params)
      end
    end
  end
end
