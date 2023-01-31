module Ivy
  class Chassis
    class RackChassis < Chassis


      #######################
      #
      # Associations
      #
      #######################

      belongs_to :rack, :class_name => "Ivy::HwRack"

    end
  end
end
