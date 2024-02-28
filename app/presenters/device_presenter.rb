#
# DevicePresenter
#
# Generic Device Presenter
#
class DevicePresenter < Presenter
  include Device::Common
  include Costed

  delegate :name, :description, :status, :metadata,
    :attributes,
    to: :o

  delegate :name, :description,
    to: :template, prefix: :template

  delegate :vcpus, :ram, :disk,
    to: :template

  delegate :additional_details, to: :details

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
      ChassisPresenter.new(o.chassis, h).location

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

  def u_height
    "#{o.chassis.u_height}U"
  end

  def details
    h.presenter_for(o.details)
  end

  def has_metadata?
    !metadata.empty?
  end

  private

  def template
    o.template
  end
end
