class Device::NetworkDetails < Device::Details

  validate :device_uses_network_template

  private

  def device_uses_network_template
    reload_device
    return unless device.present?
    unless device.template.tag == 'network'
      self.errors.add(:device, 'must use the `network` template if it has a Device::NetworkDetails')
    end
  end

end
