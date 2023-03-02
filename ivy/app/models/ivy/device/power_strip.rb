module Ivy
  class Device
    class PowerStrip < NetworkedDevice

      def generate_dsm
        now = Time.now.to_i
        startu = slot.chassis.rack_start_u rescue 0
        dsm = rack.nil? ?  "rack_0" : "rack_#{rack.id}"
        dsm += "__powerstrip__startu#{startu}__#{now}"
        dsm
      end

    end
  end
end
