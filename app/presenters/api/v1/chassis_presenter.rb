#
# Api::V1::ChassisPresenter
#
# Chassis Presenter for API
#
module Api::V1
  class ChassisPresenter < Presenter
    delegate :id, :name, :facing, :rack_end_u, :rack_start_u, :template, to: :o

    def device
      @device ||= Api::V1::DevicePresenter.new(o.device)
    end

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
