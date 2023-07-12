#
# Ivy::DeviceServices::Update
#
# Extracted from controller action. The responsibility when updating a device is that you also need to 
# update the chassis (the same form as the device has information such as the template id which goes on
# the device's chassis). 
#
# There is additional responsibility in here to update the name of the chassis if it doesn't have one. This
# should not be required, but if a chassis ever got into our system without a name (something our system should
# not allow) then this would mean that the device's chassis could never be saved. We did observe this with 
# sensors in #22948.
#
module Ivy
  module DeviceServices
    class Update
      def self.call(device, device_params, location_params, user)
        chassis = device.chassis
        location = device.location
        device.update(device_params) 

        if location && !location_params.blank?
          Ivy::DeviceServices::Move.call(location, location_params, user)
          location.save
        end

        return [device, chassis, location]
      end
    end
  end
end
