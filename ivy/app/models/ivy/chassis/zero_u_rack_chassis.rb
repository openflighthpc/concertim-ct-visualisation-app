module Ivy
  class Chassis
    class ZeroURackChassis < RackChassis


      #######################
      #
      # Associations
      #
      #######################

      belongs_to :rack, :class_name => "Ivy::HwRack"

    end
  end
end
