module Ivy
  class HwRack

    # Module grouping methods related to querying the occupation of a rack.
    module Occupation
      class InvalidRackU < ArgumentError; end

      # u_is_empty? returns true if the U is empty.
      #
      # If facing is given, the U is considered empty if it is empty, or
      # half-empty on the given facing.
      #
      # If exclude is given, the U is considered empty if it is empty or occupied
      # by the excluded device.
      #
      def u_is_empty?(u, facing:nil, exclude:nil)
        raise InvalidRackU, u if u.to_i > u_height or u.to_i < 1

        relevant_locations = locations.occupying_rack_u.where.not("start_u > ?", u).where.not("end_u < ?", u)
        relevant_locations.none? { |l| l.occupy_u?(u, facing: facing, exclude: exclude) }
      end

      def empty?
        devices.empty?
      end

      #
      # number_of_devices
      #
      def number_of_devices
        group ? (MEMCACHE.get("hacor:group:#{group.id}")[:members].size rescue 0) : 0
      end

      # Return the highest empty u for the given facing.
      # Half empty u will be included iff they are empty in the given facing.
      def highest_empty_u(facing = nil)
        if facing.nil?
          # XXX Do we need to add one and check if we're above the rack?
          locations.reject(&:zero_u?).map(&:end_u).compact.sort.last || 0
        else
          raise NotImplementedError
          # height = (u_height.nil? || u_height.blank?) ? 1 : u_height
          # first_empty_u( ( 1..height ).to_a.reverse, facing)
        end
      end

      #
      # space_used
      #
      def space_used
        value_for_metric(SPACE_USED_METRIC_KEY).to_i rescue 0
      end

      #
      # total_space
      # 
      def total_space
        u_height
      end

    end
  end
end
