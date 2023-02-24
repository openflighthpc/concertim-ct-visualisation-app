module Ivy
  class Device
    class RackTaggedDevice < TaggedDevice

      has_one :rack, foreign_key: :tagged_device_id, class_name: "Ivy::HwRack"

      def tagged_entity
        rack
      end
    end
  end
end
