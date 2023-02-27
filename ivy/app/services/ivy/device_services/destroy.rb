#
# Ivy::DeviceServices::Destroy
#
# Service for destroying a device. Destroys the device and returns success/failure boolean, a flash notice
# and a boolean representing whether this should prompt the "show destroy issues" popup to appear or not. 
# 
# If the logic in here starts to get any more complex, split out into methods. 
#
module Ivy
  module DeviceServices
    class Destroy
      def self.call(device)
        #
        # If it's a non-complex device, destory the chassis, otherwise destroy the 
        # blade only.
        #
        if device.chassis_simple?
          device.chassis.destroy
        else
          device.destroy
        end
      end
    end
  end
end
