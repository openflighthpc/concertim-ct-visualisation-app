module Ivy
  class Device
    class RackTaggedDevice < TaggedDevice


      ####################################
      #
      # Associations
      #
      ####################################

      has_one :rack, foreign_key: :tagged_device_id, class_name: "Ivy::HwRack"

    end
  end
end
