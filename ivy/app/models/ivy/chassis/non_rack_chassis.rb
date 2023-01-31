module Ivy
  class Chassis
    class NonRackChassis < Chassis

      # Non rack chassis should always be considered as facing front (like racks)
      def facing
        'f'
      end

    end
  end
end
