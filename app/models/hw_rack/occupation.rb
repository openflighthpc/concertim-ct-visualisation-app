#==============================================================================
# Copyright (C) 2024-present Alces Flight Ltd.
#
# This file is part of Concertim Visualisation App.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# Concertim Visualisation App is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with Concertim Visualisation App. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on Concertim Visualisation App, please visit:
# https://github.com/openflighthpc/concertim-ct-visualisation-app
#==============================================================================

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
    # total_space
    #
    def total_space
      u_height
    end

  end
end
