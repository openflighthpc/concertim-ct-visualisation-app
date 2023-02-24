module Ivy
  class Device
    class ChassisTaggedDevice < TaggedDevice

      def tagged_entity
        direct_chassis
      end
    end
  end
end
