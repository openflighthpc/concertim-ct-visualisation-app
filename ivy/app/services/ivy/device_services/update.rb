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
      def self.call(device, device_params, chassis_params, user)
        chassis = device.indirect_chassis
        device.update(device_params) 

        if chassis
          chassis.name = chassis.assign_name if chassis.name.blank?
          unless chassis_params.blank?
            Ivy::DeviceServices::Move.call(chassis, chassis_params, user)
          end
          chassis.save
        end

        return [device, chassis]
      end
    end
  end
end
