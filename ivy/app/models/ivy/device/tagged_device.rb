module Ivy
  class Device
    class TaggedDevice < NetworkedDevice

      #
      # tagged_entity
      #
      # Returns the entity that this tagged device is "tagged to"
      #
      def tagged_entity
        raise NotImplementedError "You should override this with each type of tagged device"
      end

    end
  end
end
