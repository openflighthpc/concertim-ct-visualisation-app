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
    delegate :id, :name, :description, :metadata,
      to: :o

    # location returns the location of the device.  For devices in simple
    # chassis, the chassis's location is returned. Devices in complex chassis,
    # are blade servers in a blade enclosure, the location of blade server in
    # the enclosure is returned.
    def location
      if o.chassis.nil?
        # This should not longer be possible.
        raise TypeError, "device does not have a chassis"

      elsif o.chassis_simple?
        # A simple device/chassis.  It's location is the location of its
        # chassis.
        Api::V1::ChassisPresenter.new(o.chassis, h).location

      elsif o.chassis_complex?
        # A blade server.
        raise NotImplementedError, "Support for complex chassis is not implemented"

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
