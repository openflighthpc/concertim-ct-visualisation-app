module Ivy
  class Chassis
    class NonRackChassis < Chassis

      ####################################
      #
      # Scopes
      #
      ####################################

      scope :excluding_ids,  ->(ids) { where.not(id: ids) }
      scope :modified_after, ->(timestamp) { where("modified_timestamp > ?", timestamp.to_i) }


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
