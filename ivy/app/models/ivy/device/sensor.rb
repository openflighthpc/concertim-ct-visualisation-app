module Ivy
  class Device
    class Sensor < NetworkedDevice

      #
      # generate_dsm
      #
      def generate_dsm
        unique = Digest::MD5.hexdigest("#{name}#{Time.now.to_i}")
        postfix = port.nil? ? '' : "_#{protocol}_#{port}" 
        "sensor-" + unique + postfix
      end

    end
  end
end
