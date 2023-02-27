#
# Ivy::DeviceServices::MoveBlade
#
# Move a blade (device) from to the specified chassis/slot.
#
module Ivy
  module DeviceServices
    class MoveBlade

      class MoveBladeError < StandardError;end


      # 
      # self.call
      #
      def self.call(device, new_slot)

        unless new_slot
          raise MoveBladeError, "No slot selected"
        end

        if new_slot.device
          raise MoveBladeError, "Slot already occupied by an existing device."
        end

        unless new_slot.compatible_with_device?(device)
          raise MoveBladeError, "Device is not compatible with this slot"
        end

        device.slot_id = new_slot.id

        if device.save
          device
        else
          raise MoveBladeError, device.errors.full_messages.join(", ")
        end
 
      end
    end
  end
end
