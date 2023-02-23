#
# Api::V1::ChassisPresenter
#
# Chassis Presenter for API
#
# There is some logic in here that tries to present a chassis as if it were a device if
# the chassis is "simple" - this is a quirk of our system. A non-simple chassis is one 
# which has multiple devices in it (like a blade centre). A "Simple" chassis is considered
# at a DB level to be a single device in a single slot of a chassis. 
#
# When presented, however, these simple chassis need to look like devices in things like
# titles.
#
module Api::V1
  class ChassisPresenter < Emma::Presenter

    #
    # location returns the location of the presented chassis relative to its
    # rack, or nil if it has no rack.
    #
    def location
      if o.in_rack?
        {
          depth: o.u_depth,
          end_u: o.rack_end_u || o.rack_start_u,
          facing: o.facing,
          rack_id: o.rack.id,
          start_u: o.rack_start_u,
          type: location_type,
        }
      elsif o.zero_u?
        {
          position: o.position,
          rack_id: o.rack.id,
          type: location_type,
        }
      else
        nil
      end
    end

    #
    # location_type returns the type (or kind) of location.  I.e., rack, zero-u
    # or non-rack.  This value determines how to interpret the value of
    # `location`.
    #
    def location_type
      if o.in_rack?
        'rack'
      elsif o.zero_u?
        'zero-u'
      else
        'non-rack'
      end
    end
  end
end
