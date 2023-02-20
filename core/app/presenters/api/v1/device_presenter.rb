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
        nil
      elsif o.chassis_simple? || o.is_a?(Ivy::Chassis)
        Api::V1::ChassisPresenter.new(o.chassis, h).location
      else
        {
          row: o.chassis_row.row_number,
          slot: o.slot.chassis_row_location,
          chassis_id: o.chassis.id,
          type: 'blade',
        }
      end
    end
  end
end
