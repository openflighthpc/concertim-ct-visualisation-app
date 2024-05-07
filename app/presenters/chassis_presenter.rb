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
# https://github.com/openflighthpc/ct-visualisation-app
#==============================================================================

class ChassisPresenter < Presenter
  # location returns a human readable string representing the position of the chassis.
  def location
    if o.in_rack?
      if o.location.u_height == 1 && o.location.full_depth?
        # Occupies the full depth of a single U.
        "U#{o.rack_start_u} of rack #{rack_link}"

      elsif o.location.u_height == 1
        # Partially occupies a single U.
        "#{o.facing} facing of U#{o.rack_start_u} of rack #{rack_link}"

      elsif o.location.full_depth?
        # Occupies the full depth of several U.
        "Between U#{o.rack_start_u} and U#{o.rack_end_u} of rack #{rack_link}"

      else
        # Partially occupies several U.
        "#{o.facing} facing between U#{o.rack_start_u} and U#{o.rack_end_u} of rack #{rack_link}"
      end

    elsif o.zero_u?
      "#{position} of rack #{rack_link}"

    else
      # A non-rack chassis.
      raise NotImplementedError, "Support for non-rack chassis has not been implemented"
    end
  end

  private

  def position
    case o.position
    when :b
      "Bottom"
    when :t
      "Top"
    when :m
      "Middle"
    else
      raise TypeError, "Unknown position type #{o.position}"
    end
  end

  def rack_link
    h.link_to(o.rack.name, h.rack_path(o.rack))
  end
end
