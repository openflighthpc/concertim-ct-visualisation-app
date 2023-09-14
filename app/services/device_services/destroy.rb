#
# DeviceServices::Destroy
#
# Service for destroying a device. Destroys the device and returns success/failure boolean.
#
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
