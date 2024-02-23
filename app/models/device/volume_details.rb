class Device::VolumeDetails < Device::Details

  validate :device_uses_volume_template

  private

  def device_uses_volume_template
    reload_device
    return unless device.present?
    unless device.template.tag == 'volume'
      self.errors.add(:device, 'must use the `volume` template if it has a Device::VolumeDetails')
    end
  end

end
