module Ivy
  class Chassis
    class NonRackChassis < Chassis

      ####################################
      #
      # Scopes
      #
      ####################################

      scope :excluding_ids,  ->(ids) { where.not(id: ids) }


      ############################
      #
      # Instance Methods
      #
      ############################


      # Non rack chassis should always be considered as facing front (like racks)
      def facing
        'f'
      end

      def rack
        nil
      end

    end
  end
end
