module Ivy
  class Chassis
    class NonRackChassis < Chassis
      def type_to_human
        "Non rack chassis"
      end

      # Non rack chassis should always be considered as facing front (like racks)
      def facing
        'f'
      end

    end
  end
end
