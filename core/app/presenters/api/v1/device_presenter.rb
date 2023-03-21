#
# Api::V1::DevicePresenter
#
# Device Presenter for the API
#
# NOTE: If this file starts becoming large / a bag of methods, split it out
# into seperate files within a `device_presenter` folder, grouped into domain
# categories, e.g., `device_presenter/location`.
module Api::V1
  class DevicePresenter < Emma::Presenter
    # Be selective about what attributes and methods we expose.
    delegate :id, :name, :description,
      to: :o

    # location returns the location of the device.  For simple devices, the
    # chassis location is returned, for complex devices, the location of blade
    # in the chassis is returned.
    def location
      if o.chassis.nil?
        # This could be a rack tagged device, data centre tagged device or
        # sensor.  For now, we're not interested in their location.
        nil

      elsif o.chassis_simple?
        # A simple device/chassis.  It's location is the location of its
        # chassis.
        Api::V1::ChassisPresenter.new(o.chassis, h).location

      elsif o.chassis_complex?
        # Either a blade enclosure or a blade server.
        if o.tagged?
          # A blade enclosure.  It's location is the location of its chassis.
          Api::V1::ChassisPresenter.new(o.chassis, h).location

        else
          # A blade server in an enclosure.  It's location is its location in
          # the enclosure.
          {
            row: o.chassis_row.row_number,
            slot: o.slot.chassis_row_location,
            chassis_id: o.chassis.id,
            type: 'blade',
          }
        end

      else
        # We shouldn't get here.
        if Rails.env.development?
          raise "Unhandled device location for #{o.id}"
        else
          Rails.logger.warn("Unhandled device location: #{o.id}")
        end
        nil
      end
    end

    def template
      # XXX Consider using a presenter here too.
      o.template
    end
  end
end
